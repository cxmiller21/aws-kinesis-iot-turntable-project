# AWS Kinesis IoT Turntable Project

The Crow Turntable company is releasing an innovative new product that will track the vinyl records that are played on their Turntable. The IoT device might be **slightly invasive**, but it will provide valuable data to the company about their customers and their listening habits.

The turntable's stylus has advanced technology that will detect when a new song is being played. The IoT devices will then send this new event to a Kinesis Data Stream. The event will contain the following data:

```json
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
  "zip_code": "12345",
  "wifi_name": "My WiFi",
  "wifi_speed": "100mbps",
}
```

## TODO

- [ ] Create a Kinesis Data Stream
- [ ] Create a Kinesis Data Firehose Delivery Stream
- [ ] Create a lambda function to process incoming data
- [ ] Create an S3 bucket to store the data as a Data Lake
- [ ] Create an Athena table to query the data
- [ ] Create an Apache Superset dashboard to visualize the data
  - [ ] Or QuickSight/Grafana?
- [ ] Create a lambda function to generate a report of the monthly data
  - [ ] Top 10 artists/songs/albums
  - [ ] Top listeners
