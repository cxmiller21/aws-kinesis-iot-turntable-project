<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

  <h3 align="center">AWS Kinesis IoT Turntable Project</h3>

  <p align="center">
    The worlds greatest IoT Turntable to never exist!
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

![IoT Turntable Screen Shot][product-screenshot]

The Crow Manufacturing company is releasing an innovative new product that will track vinyl records that are played on their latest and greatest turntable. The IoT devices might be considered as *slightly invasive*, but they will provide valuable data to the company about their customers and their listening habits.

The turntable's stylus has advanced technology that will detect when a new song is being played. The IoT devices will then send this data to an AWS Kinesis Data Stream where it will eventually be saved in an S3 Data Lake for further analysis.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Python][Python.py]][Python-url]
  * [![Java][Java.java]][Java-url] (Application alternative/incomplete example)
* [![KDS][KDS.aws]][KDS-url]
* [![KDFS][KDFS.aws]][KDFS-url]
* [![S3][S3.aws]][S3-url]
* [![GlueDataCatalog][GlueDataCatalog.aws]][GlueDataCatalog-url]
* [![GlueCrawler][GlueCrawler.aws]][GlueCrawler-url]
* [![Athena][Athena.aws]][Athena-url]
* [![SNS][SNS.aws]][SNS-url]
* [![Superset][Superset.apache]][Superset-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* AWS Account - [Sign up](https://aws.amazon.com/free)
  * [Create User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  * [Configure Credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
* AWS CLI - [Install steps](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Terraform - [Install steps](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Python - [Install steps](https://www.python.org/downloads/)
  * Macs can use `brew install python`
* Java (Optional) - [Install steps](https://www.java.com/en/download/help/download_options.html)
  * Macs can use `brew install java`

### Getting Started

#### AWS Infrastructure + Data Creation

1. Clone the repo
   ```sh
   git clone https://github.com/cxmiller21/aws-kinesis-iot-turntable-project.git
   ```
2. Create Terraform AWS Resources
   ```sh
   cd ./terraform
   terraform init
   terraform plan # Confirm resources to create
   terraform apply # Expecting 45 resources to be created
   ```
3. Push mock events to Kinesis Data Stream (Open a new terminal tab/window)
   ```python
   # (Optional) Create a limited list of new vinyl records
   # A file already exists at `./scripts/json-data/discogs_vinyl_record_data.json`
   python ./scripts/get_discogs_vinyl_records.py --record-count 20
   # Push records to Kinesis Data Stream
   python ./scripts/put_kinesis_data.py --user-count 100 --event-count 200
   ```
4. Verify data is sent to S3 Data Lake (~1 minute after running `put_kinesis_data.py` script)
   1. Navigate to S3 Console
   2. Navigate to `s3://<your-bucket-name>/`
   3. Confirm files are uploaded to `s3://<your-bucket-name>/YYYY/MM/DD/HH/file.orc`
5. Manually run the AWS Glue Crawler to update the Data Catalog
   1. Navigate to AWS Glue Console
   2. Navigate to `Crawlers` in the left menu
   3. Select `iot-turntable-default-crawler`
   4. Select `Run crawler`
   5. Navigate to `Tables` in the left menu
   6. Select `iot_turntable_default_<random-string>_data_lake`
   7. Select `Actions` dropdown --> `View data`
   8. Confirm data can be queried with AWS Athena

#### Superset Setup (Data Visualization)

1. Prerequisites
   1. [Docker](https://docs.docker.com/get-docker/)
   2. [Docker Compose](https://docs.docker.com/compose/install/)
2. Open a new terminal window outside of the `aws-kinesis-iot-turntable-project` directory
3. Clone the Apache Superset repo
   ```sh
   git clone https://github.com/apache/superset.git
   ```
4. Navigate to the `superset` directory with `cd ./superset`
5. Copy the `superset-py-requirements-local.txt` to the Superset project folder `superset/docker/` and rename the file to `requirements-local.txt`
  - This will allow us to install the AWS Athena driver for Superset
6. Pull and run the Superset Docker images
   ```sh
   docker-compose -f docker-compose-non-dev.yml pull
   docker-compose -f docker-compose-non-dev.yml up
   ```
7. Navigate to `http://localhost:8088/` in your browser
8. Login with the default credentials `username:admin` and `password:admin`

##### Superset Athena Database Setup

> From the `aws-kinesis-iot-turntable-project` project

1. Open and update the `get_athena_superset_conn.py` script and update variables
2. Run the script to get the Athena connection string
    ```sh
    python ./scripts/get_athena_superset_conn.py
    ```
3. Copy the connection string that's output and update the `<ak_id>` and `<secret_id>` with your AWS credentials that have permissions to access Athena
3. Navigate to `http://localhost:8088/databaseview/list/` in your browser
4. Add Database --> Supported Databases --> Athena
5. Paste the connection string into the `SQLAlchemy URI` field
6. Test the connection and save the database
7. Create a new Dataset
   1. Navigate to `http://localhost:8088/tablemodelview/list/`
   2. Add Dataset
      1. Database: Amazon Athena
      2. Schema: `iot-turntable-default-database`
      3. Table: `iot_turntable_default_<random-string>_data_lake`
      4. Create Dataset
8. Create a chart or test querying data from the SQL Lab
   1. Navigate to `http://localhost:8088/superset/sqllab/`
   2.  Database: Amazon Athena
   3.  Schema: `iot-turntable-default-database`
   4.  Table: `iot_turntable_default_<random-string>_data_lake`
   5.  Run Query: `SELECT * FROM "iot-turntable-default-database".iot_turntable_default_cudsg_data_lake LIMIT 10;`

Now you should be seeing data loaded from the IoT Turntable S3 Data Lake in Superset!

### Reporting

Now for the most important part, sending data to the Manufacturing team so they can see how their new product is doing!

1. Access the AWS Console and view the Lambda function page
2. Open the `iot-turntable-default-reporting-lambda` function
3. Select `Test` in the top right corner and keep the default settings
4. Run a new Test event
   1. The function should complete in about 5 to 10 seconds
   2. Optionally update the Terraform `sns_subscription_emails` variable to your email address to automatically receive the report. Otherwise view the Presigned S3 URL in the Lambda function results

Congrats! You've successfully setup the AWS Kinesis IoT Turntable Project!

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Examples TBD

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [x] Create IAM Role for Glue Crawler
- [ ] Create IAM User/Role/Policy for Superset to access Athena
- [x] Update README to include Superset setup
  - [ ] Can Superset dashboards be added to the repo for easy setup?
- [ ] Create a DynamoDB table to store vinyl record data generated in `generate_vinyl_record_data.py`
  - [ ] Modify `put_kinesis_data.py` to get records from DynamoDB
- [ ] Create a DynamoDB table to store a list of users generated in `put_kinesis_data.py`
  - [ ] Create a new script to generate mock users
  - [ ] Modify `put_kinesis_data.py` to get users from DynamoDB
- [ ] Fix/Expand the Java application to send data to the Kinesis Data Stream
- [ ] Create a Lambda function that's triggered when a file is uploaded to the Data Lake to auto-trigger a Glue Crawler

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Crow Manufacturing - [@crow_manufacturing](https://twitter.com/crow_manufacturing) - thebestturntables@crowmanufacturing.com


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

The following resources were used to help build out this project:

* [AWS Kinesis Producer - KPL Java Sample Application](https://github.com/awslabs/amazon-kinesis-producer/tree/master/java/amazon-kinesis-producer-sample)
* [othneildrew Best-README-Template](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[product-screenshot]: images/product-screenshot.png
[Python.py]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[Python-url]: https://www.python.org/
[Java.java]: https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=java&logoColor=white
[Java-url]: https://www.java.com/en/
[KDS.aws]: https://img.shields.io/badge/AWS%20Kinesis%20Data%20Stream-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[KDS-url]: https://aws.amazon.com/kinesis/data-streams/
[KDFS.aws]: https://img.shields.io/badge/AWS%20Kinesis%20Data%20Firehose%20Delivery%20Stream-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[KDFS-url]: https://aws.amazon.com/kinesis/data-firehose/
[S3.aws]: https://img.shields.io/badge/AWS%20S3-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[S3-url]: https://aws.amazon.com/s3/
[GlueDataCatalog.aws]: https://img.shields.io/badge/AWS%20Glue%20Data%20Catalog-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[GlueDataCatalog-url]: https://aws.amazon.com/glue/
[GlueCrawler.aws]: https://img.shields.io/badge/AWS%20Glue%20Crawler-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[GlueCrawler-url]: https://aws.amazon.com/glue/
[Athena.aws]: https://img.shields.io/badge/AWS%20Athena-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[Athena-url]: https://aws.amazon.com/athena/
[SNS.aws]: https://img.shields.io/badge/AWS%20SNS-4A4A55?style=for-the-badge&logo=amazonaws&logoColor=FF3E00
[SNS-url]: https://aws.amazon.com/sns/
[Superset.apache]: https://img.shields.io/badge/Apache%20Superset-4A4A55?style=for-the-badge&logo=apache&logoColor=FF3E00
[Superset-url]: https://superset.apache.org/
