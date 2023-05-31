"""
Generate Mock IoT Turntable data and send to Kinesis Data Stream

Example Event Data:
{
  "turntableId": "1234567890",
  "artist": "The Beatles",
  "album": "Abbey Road",
  "song": "Come Together",
  "play_timestamp": "2021-01-01T00:00:00.000Z",
  "rpm": 33,
  "volume": 50,
  "speaker": "headphones",
  "owner": "John Doe",
  "email": "example@gmail.com",
  "zip_code": "12345",
  "wifi_name": "My WiFi",
  "wifi_speed": "100mbps",
}
"""

import argparse
import boto3
import json
import logging
import time

from faker import Faker

STREAM_NAME = "aws-kinesis-iot-turntable-stream"
EPOCH_TIME = str(time.time())

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Generating and sending mock IoT Turntable event data...")

kinesis = boto3.client("kinesis")
fake = Faker()


def get_arguments() -> tuple[int]:
    """Parse command line arguments - Currently only service name"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--number-of-events",
        help="Number of events to generate. Default is 1",
        default="1",
    )
    args = parser.parse_args()
    return int(args.number_of_events)


def generate_mock_vinyl_data(number_of_vinyl: int) -> list[dict]:
    """Generate mock vinyl albums"""
    mock_vinyl_albums = []
    for _ in range(number_of_vinyl):
        mock_vinyl = {
            "album_name": fake.sentence(
                nb_words=3, variable_nb_words=True, ext_word_list=None
            ),
            "artist": fake.name(),
            "songs": [
        }
        mock_vinyl_albums.append(mock_vinyl)
    return mock_vinyl_albums


def get_turntable_data(number_of_events: int) -> list:
    """Generate mock IoT Turntable data"""
    data = []
    for _ in range(number_of_events):
        data.append(
            {
                "turntableId": fake.uuid4(),
                "artist": fake.name(),
                "album": fake.name(),
                "song": fake.name(),
                "play_timestamp": fake.iso8601(),
                "rpm": fake.random_int(min=33, max=45),
                "volume": fake.random_int(min=0, max=100),
                "speaker": fake.word(),
                "owner": fake.name(),
                "email": fake.ascii_email(),
                "zip_code": fake.zipcode(),
                "wifi_name": fake.word(),
                "wifi_speed": fake.word(),
            }
        )
    return data


def put_kinesis_data(data: list) -> dict:
    results = kinesis.put_record(
        StreamName=STREAM_NAME, Data=json.dumps(data), PartitionKey=EPOCH_TIME
    )
    return results


def main() -> None:
    number_of_events = get_arguments()
    data = get_turntable_data(number_of_events)
    results = put_kinesis_data(data)
    print(results)


if __name__ == "__main__":
    main()
