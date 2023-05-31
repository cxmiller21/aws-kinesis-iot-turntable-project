import boto3
import json
import time

kinesis = boto3.client('kinesis')

STREAM_NAME = "aws-kinesis-iot-turntable-stream"
EPOCH_TIME = str(time.time())


def put_kinesis_data(data):
    results = kinesis.put_record(
        StreamName=STREAM_NAME,
        Data=json.dumps(data),
        PartitionKey=EPOCH_TIME
    )
    return results


def main():
  data = {'this': 'is', 'a': 'test'}
  results = put_kinesis_data(data)
  print(results)

if __name__ == '__main__':
  main()
