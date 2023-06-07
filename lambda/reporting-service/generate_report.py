"""Lambda function to generate monthly reports with saved Athena queries

Trigger:
    CloudWatch Event Rule - Schedule: cron(0 0 1 * ? *)
    The Lambda function is triggered by a CloudWatch Event Rule. The rule
    is configured to trigger the function on the first day of each month.

Destination:
    The Lambda function has an SNS Topic destination. The results from the
    function will then be sent to the topic where a "Managers" email list
    is subscribed. This will allow the managers to receive a monthly email
    with the presigned URLs for the reports.

Description:
    This function will query Athena for all available named queries and
    filter out any that do not start with a defined prefix. It will then
    run each of the matching queries and upload the results to S3. Finally,
    it will generate a presigned URL for each report and return them in the
    response body.

Environment Variables:
    ATHENA_S3_REPORTING_BUCKET: S3 bucket to store Athena query results
    ATHENA_S3_REPORTING_PATH: S3 path to store Athena query results
    ATHENA_NAMED_QUERY_PREFIX: Prefix to filter Athena named queries
    REPORTING_SERVICE_S3_BUCKET: S3 bucket to store report results
    GLUE_DATABASE_NAME: Glue database name
    GLUE_DATABASE_TABLE: Glue table name

Returns:
    {
        "statusCode": 200,
        "body": {
            "reports_generated": 0,
            "s3_presigned_urls": [],
        },
    }
"""
import boto3
import csv
import os
import logging
import time

from botocore.exceptions import ClientError
from datetime import datetime
from io import StringIO

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    force=True,
)

log = logging.getLogger(__name__)
log.info("Generating IoT Turntable Reports...")

client = boto3.client("athena")
s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

# Environment variables
ATHENA_S3_REPORTING_BUCKET = os.environ["ATHENA_S3_REPORTING_BUCKET"]
ATHENA_S3_REPORTING_PATH = os.environ["ATHENA_S3_REPORTING_PATH"]
ATHENA_NAMED_QUERY_PREFIX = os.environ["ATHENA_NAMED_QUERY_PREFIX"]
REPORTING_SERVICE_S3_BUCKET = os.environ["REPORTING_SERVICE_S3_BUCKET"]
REPORTING_SERVICE_S3_PREFIX = "monthly-reports"
REPORTING_SERVICE_SNS_TOPIC_ARN = os.environ["REPORTING_SERVICE_SNS_TOPIC_ARN"]
GLUE_DATABASE = os.environ["GLUE_DATABASE_NAME"]
GLUE_DATABASE_TABLE = os.environ["GLUE_DATABASE_TABLE"].replace(
    "non_crawler_2023", "data_lake"
)


def handle_next_token(callback_function: callable, filter: str, **kwargs) -> list[dict]:
    """Handle pagination for Boto3 responses with NextToken"""
    response = callback_function(**kwargs)
    data = response[filter]
    results = data if isinstance(data, list) else [data]

    # Handle pagination
    while "NextToken" in response:
        log.info(f"NextToken found - Paginating results")
        response = callback_function(NextToken=response["NextToken"], **kwargs)
        results.extend(response[filter])

    return results


def list_athena_named_queries() -> list[str]:
    """Get the Athena NamedQueryId of all available queries"""
    return handle_next_token(client.list_named_queries, "NamedQueryIds")


def get_athena_reporting_named_queries(named_query_ids: list[str]) -> list[dict]:
    """Get the Athena named queries of available reporting queries"""
    results = []
    for named_query_id in named_query_ids:
        response = client.get_named_query(NamedQueryId=named_query_id)["NamedQuery"]
        if not response["Name"].startswith(ATHENA_NAMED_QUERY_PREFIX):
            continue
        log.info(f"Found reporting query: {response['Name']}")
        results.append({"name": response["Name"], "query": response["QueryString"]})
    return results


def start_reporting_query(query_string: str) -> dict:
    """Query Athena to get reporting data"""
    response = client.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={"Database": GLUE_DATABASE},
        ResultConfiguration={
            "OutputLocation": f"s3://{ATHENA_S3_REPORTING_BUCKET}/{ATHENA_S3_REPORTING_PATH}"
        },
    )
    return response


def has_query_succeeded(query_execution_id: str) -> bool:
    state = "RUNNING"
    max_execution = 10

    while max_execution > 0 and state in ["RUNNING", "QUEUED"]:
        max_execution -= 1
        response = client.get_query_execution(QueryExecutionId=query_execution_id)
        log.info(f"State response: {response}")
        if (
            "QueryExecution" in response
            and "Status" in response["QueryExecution"]
            and "State" in response["QueryExecution"]["Status"]
        ):
            state = response["QueryExecution"]["Status"]["State"]
            if state == "SUCCEEDED":
                return True

        # Poll every 3 seconds
        # This should probably be longer in real world use cases
        # Since the amount of data being queried is very small,
        # this interval will work.
        time.sleep(3)

    return False


def clean_athena_query_results(data: list[dict]) -> dict[list[str], list[dict]]:
    """Condense data from Athena query results"""
    headers = [value["VarCharValue"] for value in data[0]["Rows"][0]["Data"]]
    rows = []
    for item in data:
        for row in item["Rows"]:
            row_data = []
            for value in row["Data"]:
                if value["VarCharValue"] in headers:
                    continue
                row_data.append(value["VarCharValue"])
            if not row_data:
                continue
            rows.append(row_data)
    return {"headers": headers, "rows": rows}


def get_query_results(query_execution_id: str) -> dict[str, list[dict]]:
    """Get Athena query execution results"""
    response = handle_next_token(
        client.get_query_results, "ResultSet", QueryExecutionId=query_execution_id
    )
    return clean_athena_query_results(response)


def write_data_to_s3(file_name: str, data: list[dict]) -> tuple[int, dict]:
    """Write report csv data to S3"""
    csv_buffer = StringIO()
    csv_writer = csv.writer(csv_buffer)
    csv_writer.writerows(data)

    results = s3_client.put_object(
        Bucket=REPORTING_SERVICE_S3_BUCKET,
        Key=f"{REPORTING_SERVICE_S3_PREFIX}/{file_name}",
        Body=csv_buffer.getvalue(),
    )
    status_code = results["ResponseMetadata"]["HTTPStatusCode"]
    return status_code, results


def create_presigned_url(file_name: str) -> str | None:
    """Generate a presigned URL to share an S3 object"""
    key = f"{REPORTING_SERVICE_S3_PREFIX}/{file_name}"
    try:
        response = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": REPORTING_SERVICE_S3_BUCKET, "Key": key},
            ExpiresIn=3600,
        )
    except ClientError as e:
        log.error(e)
        return None
    return response


def send_sns_notification(response_body: dict[int, list[str]]) -> dict:
    """Send SNS notification with report results"""
    message = f"Monthly IoT Turntable Reports: {response_body['reports_generated']} reports generated"
    for url in response_body["s3_presigned_urls"]:
        message += f"\n{url}"
    log.info(f"Sending SNS notification: {message}")
    response = sns_client.publish(
        TopicArn=REPORTING_SERVICE_SNS_TOPIC_ARN,
        Message=message,
    )
    return response


def lambda_handler(event, context):
    log.info("Generating report...")
    log.info(
        f"GLUE_DATABASE: {GLUE_DATABASE} - GLUE_DATABASE_TABLE: {GLUE_DATABASE_TABLE}"
    )

    named_query_ids = list_athena_named_queries()
    reporting_queries = get_athena_reporting_named_queries(named_query_ids)
    log.info(f"Found {len(reporting_queries)} Reporting Named Queries")

    response_body = {
        "reports_generated": 0,
        "s3_presigned_urls": [],
    }
    for reporting_query in reporting_queries:
        query_string = reporting_query["query"]
        log.info(f"Running query: {query_string}")
        query_execution = start_reporting_query(query_string)
        query_execution_id = query_execution["QueryExecutionId"]

        query_succeeded = has_query_succeeded(query_execution_id)
        log.info(f"Query Succeeded: {query_succeeded}")

        if not query_succeeded:
            log.error(f"Query failed!: {query_execution}")
            return {"statusCode": 500, "body": "Report failed!"}

        query_data = get_query_results(query_execution_id)
        csv_data = [query_data["headers"]] + query_data["rows"]

        query_name = reporting_query["name"].replace("_", "-").lower()
        # Format: YYYYMMDD (Add %H%M%S for more detail)
        timestamp = datetime.now().strftime("%Y-%m-%d")
        file_name = f"{query_name}-{timestamp}.csv"
        status_code, upload_results = write_data_to_s3(file_name, csv_data)
        if status_code != 200:
            log.error(f"Error uploading report to S3: {file_name}")
            log.error(upload_results)
            continue

        response_body["reports_generated"] += 1
        presigned_url = create_presigned_url(file_name)
        response_body["s3_presigned_urls"].append(presigned_url)

    sns_notification_results = send_sns_notification(response_body)
    log.info(f"SNS Notification Results: {sns_notification_results}")

    return {
        "statusCode": 200,
        "body": response_body,
        "notification_results": sns_notification_results,
    }
