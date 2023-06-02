import boto3
import os
import logging
import time

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    force=True,
)

log = logging.getLogger(__name__)
log.info("Generating IoT Turntable Reports...")

client = boto3.client("athena")

# Environment variables
ATHENA_S3_REPORTING_BUCKET = os.environ["ATHENA_S3_REPORTING_BUCKET"]
GLUE_DATABASE = os.environ["GLUE_DATABASE_NAME"]
GLUE_DATABASE_TABLE = os.environ["GLUE_DATABASE_TABLE"].replace(
    "non_crawler_2023", "data_lake"
)


def start_reporting_query() -> dict:
    """Query Athena to get reporting data"""
    response = client.start_query_execution(
        QueryString=f"SELECT turntableId FROM {GLUE_DATABASE_TABLE} LIMIT 10;",
        QueryExecutionContext={"Database": GLUE_DATABASE},
        ResultConfiguration={"OutputLocation": f"s3://{ATHENA_S3_REPORTING_BUCKET}/reporting-service/"},
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

        time.sleep(15)

    return False


def get_query_results(query_execution_id: str):
    """Get Athena query execution results"""
    response = client.get_query_results(QueryExecutionId=query_execution_id)
    return response["ResultSet"]["Rows"]


def transform_reporting_data(data: list[dict]):
    """Transform reporting data"""
    return "Transformed reporting data"


def lambda_handler(event, context):
    log.info("Generating report...")
    log.info(f"GLUE_DATABASE: {GLUE_DATABASE} - GLUE_DATABASE_TABLE: {GLUE_DATABASE_TABLE}")


    query_execution = start_reporting_query()
    query_execution_id = query_execution["QueryExecutionId"]

    query_succeeded = has_query_succeeded(query_execution_id)
    log.info(f"Query Succeeded: {query_succeeded}")

    if not query_succeeded:
      log.error(f"Query failed!: {query_execution}")
      return {"statusCode": 500, "body": "Report failed!"}

    raw_data = get_query_results(query_execution_id)
    log.info(f"Raw data: {raw_data}")

    return {"statusCode": 200, "body": "Report generated!"}
