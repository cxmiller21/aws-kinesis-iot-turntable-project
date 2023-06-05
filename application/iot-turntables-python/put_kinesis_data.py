"""
Generate Mock IoT Turntable data and send to Kinesis Data Stream
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
VINYL_RECORD_FILE = "./discogs_vinyl_record_data.json"

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Generating and sending mock IoT Turntable event data...")

kinesis = boto3.client("kinesis")
fake = Faker("en_US")
start_time = datetime.now()


def get_arguments() -> tuple[int, int, int]:
    """Parse command line arguments - Currently only service name"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--user-count",
        help="Number of IoT users to generate data for. Default is 100",
        default="100",
    )
    parser.add_argument(
        "--event-count",
        help="Number of events generate. Default is 10",
        default="10",
    )
    parser.add_argument("--run-time", help="Number of seconds to run", default="60")
    args = parser.parse_args()
    return (
        int(args.user_count),
        int(args.event_count),
        int(args.run_time),
    )


def get_turntable_users(number_of_users: int) -> list[dict]:
    """Generate mock IoT Turntable users"""
    mock_users = []
    wifi_speeds = [100, 400, 1000, 1200, 2000]

    for _ in range(number_of_users):
        # Note - user lat/long will NOT match user zip code/state
        latitude, longitude = fake.location_on_land(coords_only=True)
        state_code = fake.state_abbr(include_territories=False)
        zip_code = fake.zipcode_in_state(state_abbr=state_code)
        mock_user = {
            "turntableId": fake.uuid4(),
            "user_name": fake.name(),
            "user_email": fake.ascii_free_email(),
            "user_zip_code": zip_code,
            "user_wifi_name": fake.word(),
            "user_wifi_mbps": wifi_speeds[fake.random_int(min=0, max=4)],
            "user_ip_address": fake.ipv4(),
            "user_latitude": latitude,
            "user_longitude": longitude,
            "user_iso_code": f"{fake.current_country_code()}-{state_code}",
        }
        mock_users.append(mock_user)
    return mock_users


def get_vinyl_record_data(file_name: str) -> list[dict]:
    """Get vinyl record data from JSON file"""
    results = []
    with open(file_name, encoding="utf-8") as f:
        results = json.load(f)
    return results


def get_event_data(user: dict, record: dict) -> dict:
    """Generate a mock IoT Turntable event"""
    turntable_rpms = [33, 45, 78]
    turntable_speakers = ["headphones", "wire-speaker", "bluetooth-speaker"]

    # Convert datetime to epoch milliseconds for IoT Analytics
    # epoch_milliseconds = fake.date_time_this_month().timestamp() * 1000
    play_timestamp = fake.date_time_this_month().isoformat().replace("T", " ")

    turntable_data = {
        "turntableId": user["turntableId"],
        "artist": record["artist"],
        "album": record["album"],
        "song": random.choice(record["songs"]),
        "play_timestamp": play_timestamp,
        "rpm": random.choice(turntable_rpms),
        "volume": fake.random_int(min=0, max=100),
        "speaker": random.choice(turntable_speakers),
    }

    # Merge user and turntable data
    return {**user, **turntable_data}


def put_kinesis_data_record(data: dict, partition_key: str) -> dict:
    """Put IoT Turntable data to Kinesis Data Stream

    Each PutRecords request can support up to 500 records.
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis/client/put_records.html
    """
    results = kinesis.put_record(
        StreamName=STREAM_NAME, Data=json.dumps(data), PartitionKey=partition_key
    )
    return results


def main() -> None:
    user_count, event_count, run_time = get_arguments()
    users = get_turntable_users(user_count)
    vinyl_records = get_vinyl_record_data(VINYL_RECORD_FILE)

    log.info("Generating mock IoT Turntable data...")
    log.info(f"Generating random user data every 5 seconds over {run_time} seconds")

    total_records_sent_to_kinesis = 0
    error_count = 0

    log.info(f"Generating {event_count} random events for {len(users)} random users...")

    event_data = []
    for _ in range(event_count):
        random_user = random.choice(users)
        random_record = random.choice(vinyl_records)
        data = get_event_data(random_user, random_record)
        event_data.append(data)

    partition_key = str(time.time())  # use timestamp as partition key

    log.info(f"Sending {len(event_data)} records to Kinesis Data Stream")
    for data in event_data:
        # log.info(f"Event: {data}")
        response = put_kinesis_data_record(data, partition_key)
        if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
            log.error(response)
            error_count += 1
        else:
            total_records_sent_to_kinesis += 1

    log.info(
        f"Successfully sent {total_records_sent_to_kinesis} IoT Turntable events to Kinesis!!"
    )

    if error_count > 0:
        log.error(f"Encountered {error_count} errors sending data to Kinesis")

    log.info(f"Script execution time: {datetime.now() - start_time}")


if __name__ == "__main__":
    main()
