"""
This script is used to generate an Apache Superset Athena connection string

Update the following variables:
    AWS_ACCESS_KEY (optional)
    AWS_SECRET_KEY (optional)
    SCHEMA_NAME (as needed)
    S3_STAGING_DIR (Use the bucket generated from Terraform)
    AWS_REGION (as needed)

1. Run this script
2. Copy the output
3. Update the <ak_id> and <ak_secret> with your AWS credentials
4. Access Superset at http://localhost:8088
5. Go to Settings --> Databases --> Add Database
6. Select Athena and paste the connection string into the SQLALCHEMY URI field
7. Test the connection and save
"""

AWS_ACCESS_KEY = "<ak_id>"
AWS_SECRET_KEY = "<ak_secret>"
SCHEMA_NAME = "iot-turntable-default-database"
S3_STAGING_DIR = "s3://iot-turntable-default-athena-query-results"
AWS_REGION = "us-east-1"


superset_athena_conn_str = (
    f"awsathena+rest://{AWS_ACCESS_KEY}:{AWS_SECRET_KEY}@"
    f"athena.{AWS_REGION}.amazonaws.com:443/"
    f"{SCHEMA_NAME}?s3_staging_dir={S3_STAGING_DIR}"
)

print("Superset Athena Connection String:")
print(superset_athena_conn_str)
