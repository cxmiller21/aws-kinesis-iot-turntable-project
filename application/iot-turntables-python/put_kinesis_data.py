"""
Generate Mock IoT Turntable data and send to Kinesis Data Stream

Example Event Data:
{
  "turntableId": "1234567890",
  "user_name": "John Doe",
  "user_email": "example@gmail.com",
  "user_address": "123 Main St",
  "user_zip_code": "12345",
  "user_wifi_name": "My WiFi",
  "user_wifi_mbps": 400,
  "user_ip_address": "1.1.1.1"
  "user_local_latlng": "123.456, 123.456",
  "artist": "The Beatles",
  "album": "Abbey Road",
  "song": "Come Together",
  "play_timestamp": "2021-01-01T00:00:00.000Z",
  "rpm": 33,
  "volume": 50,
  "speaker": "headphones",
}
"""

import argparse
import boto3
import json
import logging
import time
import random

from datetime import datetime
from faker import Faker

STREAM_NAME = "aws-kinesis-iot-turntable-default-stream"
VINYL_RECORD_FILE = "./vinyl_record_data.json"

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Generating and sending mock IoT Turntable event data...")

kinesis = boto3.client("kinesis")
fake = Faker()


def get_arguments() -> tuple[int, int, int]:
    """Parse command line arguments - Currently only service name"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--user-count",
        help="Number of IoT users to generate data for. Default is 1",
        default="1",
    )
    parser.add_argument("--run-time", help="Number of seconds to run", default="60")
    parser.add_argument(
        "--sleep-interval",
        help="Number of seconds to wait after sending data to Kinesis",
        default="5",
    )
    args = parser.parse_args()
    return (
        int(args.user_count),
        int(args.run_time),
        int(args.sleep_interval),
    )


def get_turntable_users(number_of_users: int) -> list[dict]:
    """Generate mock IoT Turntable users"""
    mock_users = []
    wifi_speeds = [100, 400, 1000, 1200, 2000]
    for _ in range(number_of_users):
        mock_user = {
            "turntableId": fake.uuid4(),
            "user_name": fake.name(),
            "user_email": fake.ascii_free_email(),
            "user_zip_code": fake.zipcode(),
            "user_wifi_name": fake.word(),
            "user_wifi_mbps": wifi_speeds[fake.random_int(min=0, max=4)],
            "user_ip_address": fake.ipv4(),
            "user_local_latlng": fake.local_latlng(country_code="US"),
        }
        mock_users.append(mock_user)
    return mock_users


def get_mock_vinyl_data(file_name: str) -> list[dict]:
    """Get vinyl record data with between 2 and 7 songs"""
    results = []
    with open(file_name) as f:
        results = json.load(f)
    return results


def get_event_data(user: dict, record: dict) -> dict:
    """Generate a mock IoT Turntable event"""
    turntable_rpms = [33, 45, 78]
    turntable_speakers = ["headphones", "wire-speaker", "bluetooth-speaker"]

    # Convert datetime to epoch milliseconds for IoT Analytics
    # epoch_milliseconds = fake.date_time_this_month().timestamp() * 1000
    play_timestamp = fake.date_time_this_month().isoformat().replace("T", " ")
    return {
        "turntableId": user["turntableId"],
        "artist": record["artist"],
        "album": record["album"],
        "song": random.choice(record["songs"]),
        "play_timestamp": play_timestamp,
        "rpm": random.choice(turntable_rpms),
        "volume": fake.random_int(min=0, max=100),
        "speaker": random.choice(turntable_speakers),
        "user_name": user["user_name"],
        "user_email": user["user_email"],
        "user_zip_code": user["user_zip_code"],
        "user_wifi_name": user["user_wifi_name"],
        "user_wifi_speed": user["user_wifi_mbps"],
        "user_ip_address": user["user_ip_address"],
        "user_local_latlng": f"{user['user_local_latlng'][0]} {user['user_local_latlng'][1]}",
    }


def put_kinesis_data_record(data: list[dict], partition_key: str) -> dict:
    """Put IoT Turntable data to Kinesis Data Stream

    Each PutRecords request can support up to 500 records.
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis/client/put_records.html
    """
    # Add a comma to the end of the data
    results = kinesis.put_record(
        StreamName=STREAM_NAME, Data=json.dumps(data), PartitionKey=partition_key
    )
    # return {"results": results, "data_count": len(data)}
    # TODO: Add error handling for failed records HTTPStatusCode != 200
    return results


def main() -> None:
    user_count, run_time, sleep_interval = get_arguments()
    users = get_turntable_users(user_count)
    vinyl_records = get_mock_vinyl_data(VINYL_RECORD_FILE)

    log.info("Generating mock IoT Turntable data...")
    log.info(f"Generating random user data every 5 seconds over {run_time} seconds")

    total_records_sent_to_kinesis = 0
    end_time = time.time() + run_time
    while time.time() < end_time:
        sample_min = len(users) / 2
        sample_max = len(users)
        sample_size = fake.random_int(min=sample_min, max=sample_max)
        random_user_data = random.sample(users, k=sample_size)
        log.info(f"Generating data for {len(random_user_data)} users")

        event_data = []
        for user in random_user_data:
            random_record = random.choice(vinyl_records)
            data = get_event_data(user, random_record)
            event_data.append(data)

        # log.info(event_data)
        partition_key = str(time.time())  # use timestamp as partition key

        # Send individual records to Kinesis Data Stream
        # More realistic for 1 user with 1 turntable
        log.info(f"Sending {len(event_data)} records to Kinesis Data Stream")
        for data in event_data:
            response = put_kinesis_data_record(data, partition_key)
            if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
                error_message = "Failed to send record to Kinesis Data Stream"
                error_message += f"\nShardID: {response['ShardId']}"
                error_message += f"\nSequenceNumber: {response['SequenceNumber']}"
                error_message += f"\nError Code: {response['ResponseMetadata']['HTTPStatusCode']}"
                error_message += f"\nRetry Attempts: {response['ResponseMetadata']['RetryAttempts']}"
                log.error(error_message)

            total_records_sent_to_kinesis += 1

        log.info(f"Sleeping for 5 seconds...")
        time.sleep(sleep_interval)

    log.info(
        f"Total records sent to Kinesis Data Stream: {total_records_sent_to_kinesis}"
    )
    log.info("Successfully generated and sent mock IoT Turntable data to Kinesis!")


if __name__ == "__main__":
    main()
