"""
Get Vinyl Records from the Discogs API and write them to a new JSON file.
These will be used in the put_kinesis_data.py script to
persist the pool or records to send to the Kinesis Data Stream.

TODO:
- Add additional metadata to the vinyl records
  - Condition
  - Price
  - Record year
  - Genre(s)
  - Label
  - RPM
  - etc.

"""

import argparse
import discogs_client
import json
import logging
import random

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Getting Vinyl Records from Discogs API...")

OUTPUT_FILE_NAME = "discogs_vinyl_record_data.json"

# https://www.discogs.com/developers
# https://github.com/joalla/discogs_client
client = discogs_client.Client("IotTurntableApp/0.1")


def get_arguments() -> tuple[int]:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--record-count",
        help="Number of vinyl records to generate data for. Default is 2",
        default="2",
    )
    args = parser.parse_args()
    return int(args.record_count)


def encode_string(string: str) -> str:
    """Decode string"""
    # return string.encode("utf-8").decode("unicode-escape")
    # return string.encode("ascii", "replace").decode("ascii") # works but outputs many ??????
    # return string.encode("utf-8").decode("utf-8", "replace")
    # return string.encode("utf-8")
    log.info(f"Type of string: {type(string)}")
    return string


def get_discogs_vinyl_records(record_count: int, user_inventory: list) -> list[dict]:
    """Get vinyl records from the Discogs API"""
    vinyl_albums = []

    user_inventory_len = len(user_inventory)
    log.info(f"User has {len(user_inventory)} records in their inventory")

    unique_albums = []
    skipped_count = 0
    for _ in range(record_count):
        record = user_inventory[random.randint(1, user_inventory_len - 1)].release

        album = encode_string(record.title)
        if album in unique_albums:
            log.info(f"Album {album} already added... skipping")
            skipped_count += 1
            continue
        unique_albums.append(album)

        mock_vinyl = {
            "album": encode_string(record.title),
            "artist": encode_string(record.artists[0].name),
            "songs": [encode_string(track.title) for track in record.tracklist],
        }
        vinyl_albums.append(mock_vinyl)

    log.info(f"Retrieved: {len(vinyl_albums)} vinyl records - Skipped: {skipped_count}")
    return vinyl_albums


def main() -> None:
    record_count = get_arguments()

    discogs_user = "Origami_Records"
    user_inventory = client.user(discogs_user).inventory

    vinyl_records = get_discogs_vinyl_records(record_count, user_inventory)
    log.info(f"Vinyl Records: {vinyl_records}")

    # write results to new JSON file
    with open(OUTPUT_FILE_NAME, "w", encoding="utf-8") as f:
        # Need to set ensure_ascii=False to write non-ASCII characters
        # Origami_Records is a Japanese shop and has non-ASCII characters
        # But other shops will also have these characters
        json.dump(vinyl_records, f, indent=4, ensure_ascii=False)


if __name__ == "__main__":
    main()
