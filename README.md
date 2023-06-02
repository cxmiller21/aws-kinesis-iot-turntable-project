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
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
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

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/cxmiller21/aws-kinesis-iot-turntable-project.git
   ```
2. Create Terraform AWS Resources
   ```sh
   cd ./terraform
   terraform init
   terraform plan # Confirm resources
   terraform apply
   ```
3. Push mock events to Kinesis Data Stream
   ```python
   cd ./application/iot-turntables-python
   # Create limited list of records to use locally
   python3 generate_vinyl_record_data.py --record-count 20
   # Push records to Kinesis Data Stream
   python3 put_kinesis_data.py --user-count 100 --event-count 200
   ```
4. Verify data is sent to S3 Data Lake
   1. Navigate to S3 Console
   2. Navigate to `s3://<your-bucket-name>/`
   3. Confirm files are uploaded to `s3://<your-bucket-name>/YYYY/MM/DD/HH/file.orc`
5. Manually run the AWS Glue Crawler to update the Data Catalog
   1. Navigate to AWS Glue Console
   2. Navigate to `Crawlers` in the left menu
   3. Select `aws-kinesis-iot-turntable-default-crawler`
   4. Select `Run crawler`
   5. Navigate to `Tables` in the left menu
   6. Select `aws_kinesis_iot_turntable_default_data_lake`
   7. Select `View data`
   8. Confirm data can be queried with AWS Athena

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Examples TBD

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [ ] Create IAM Role for Glue Crawler
- [ ] Create IAM User/Role/Policy for Superset to access Athena
- [ ] Update README to include Superset setup
  - [ ] Can Superset dashboards be added to the repo for easy setup?
- [ ] Create a DynamoDB table to store vinyl record data generated in `generate_vinyl_record_data.py`
  - [ ] Modify `put_kinesis_data.py` to get records from DynamoDB
- [ ] Create a DynamoDB table to store a list of users generated in `put_kinesis_data.py`
  - [ ] Create a new script to generate mock users
  - [ ] Modify `put_kinesis_data.py` to get users from DynamoDB
- [ ] TBD

See the [open issues](https://github.com/othneildrew/Best-README-Template/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Crow Manufacturing - [@crow_manufacturing](https://twitter.com/crow_manufacturing) - thebestturntables@crowmanufacturing.com


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

Use this space to list resources you find helpful and would like to give credit to. I've included a few of my favorites to kick things off!

This project was assisted by the following resources:

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
