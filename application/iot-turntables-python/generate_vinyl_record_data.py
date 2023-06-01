"""
Generate Mock Vinyl Records and write to a new JSON file.
These will be used in the put_kinesis_data.py script to
persist the pool or records to send to the Kinesis Data Stream.
"""

import argparse
import json
import logging
import random

from faker import Faker

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Generating mock record data...")

fake = Faker()


def get_arguments() -> tuple[int]:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--record-count",
        help="Number of vinyl records to generate data for. Default is 20",
        default="20",
    )
    args = parser.parse_args()
    return int(args.record_count)


def generate_mock_vinyl_songs(number_of_songs: int) -> str:
    """Generate mock vinyl songs"""
    mock_songs = []
    for _ in range(number_of_songs):
        song_name = fake.sentence(
            nb_words=3, variable_nb_words=True, ext_word_list=None
        )
        mock_songs.append(song_name.replace(".", ""))
    return mock_songs


def generate_mock_vinyl_data(number_of_vinyl: int) -> list[dict]:
    """Generate mock vinyl albums with between 2 and 7 songs"""
    mock_vinyl_albums = []
    for _ in range(number_of_vinyl):
        album_name = fake.sentence(
            nb_words=3, variable_nb_words=True, ext_word_list=None
        )
        mock_vinyl = {
            "album": album_name.replace(".", ""),
            "artist": fake.name(),
            "songs": generate_mock_vinyl_songs(fake.random_int(min=2, max=7)),
        }
        mock_vinyl_albums.append(mock_vinyl)
    return mock_vinyl_albums


def main() -> None:
    record_count = get_arguments()
    vinyl_records = generate_mock_vinyl_data(record_count)

    log.info(f"Generated {len(vinyl_records)} mock vinyl records")

    # write results to new JSON file
    with open("vinyl_record_data.json", "w") as f:
        json.dump(vinyl_records, f, indent=4)


if __name__ == "__main__":
    main()
