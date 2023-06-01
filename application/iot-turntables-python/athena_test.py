"""
This script is used to generate the Superset Athena connection string.

Update the following variables:
    AWS_ACCESS_KEY
    AWS_SECRET_KEY
    SCHEMA_NAME (as needed)
    S3_STAGING_DIR (as needed)
    AWS_REGION (as needed)

1. Run this script
2. Copy the output
3. Access Superset at http://localhost:8088
4. Go to Settings --> Databases --> Add Database
5. Select Athena and paste the connection string into the SQLALCHEMY URI field
6. Test the connection and save
"""

AWS_ACCESS_KEY = ""
AWS_SECRET_KEY = ""
SCHEMA_NAME = "aws-kinesis-iot-turntable-default-database"
S3_STAGING_DIR = "s3://aws-kinesis-iot-turntable-default-athena-query-results"
AWS_REGION = "us-east-1"


superset_athena_conn_str = (
    f"awsathena+rest://{AWS_ACCESS_KEY}:{AWS_SECRET_KEY}@"
    f"athena.{AWS_REGION}.amazonaws.com:443/"
    f"{SCHEMA_NAME}?s3_staging_dir={S3_STAGING_DIR}"
)

print("Superset Athena Connection String:")
print(superset_athena_conn_str)
