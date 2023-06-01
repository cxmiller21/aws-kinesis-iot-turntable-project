#####################################################
# Athena Resources for Querying and Analyzing IoT Turntable Data
#####################################################
# resource "aws_athena_data_catalog" "iot_turntable" {
#   name        = "${local.project_prefix}-data-catalog}"
#   description = "IoT Turntable Data Catalog"
#   type        = "LAMBDA"

#   parameters = {
#     "function" = "arn:aws:lambda:eu-central-1:123456789012:function:not-important-lambda-function"
#   }

#   tags = {
#     Name = "example-athena-data-catalog"
#   }
# }

# resource "aws_athena_database" "iot_turntable" {
#   name   = replace("${local.project_prefix}-database", "-", "_")
#   bucket = aws_s3_bucket.iot_turntable_data_lake.id

#   depends_on = [
#     aws_s3_bucket.iot_turntable_data_lake,
#   ]
# }
