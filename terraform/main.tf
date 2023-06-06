data "aws_caller_identity" "current" {}

resource "random_string" "bucket_suffix" {
  length  = 5
  lower   = true
  upper   = false
  special = false
  numeric = false
}

locals {
  account_id                    = data.aws_caller_identity.current.account_id
  project_prefix                = "${var.project_name}-${terraform.workspace}"
  s3_data_lake_bucket_name      = "${local.project_prefix}-data-lake"
  s3_athena_results_bucket_name = "${local.project_prefix}-athena-query-results"
  # TODO: Uncomment the following lines to use random bucket names
  # s3_data_lake_bucket_name      = "${local.project_prefix}-${random_string.bucket_suffix.id}-data-lake"
  # s3_athena_results_bucket_name = "${local.project_prefix}-${random_string.bucket_suffix.id}-athena-query-results"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

#####################################################
# S3 Bucket for IoT Turntable Data from Kinesis
#####################################################
resource "aws_s3_bucket" "iot_turntable_data_lake" {
  bucket        = local.s3_data_lake_bucket_name
  force_destroy = false

  tags = merge(
    var.default_tags,
    {
      Name        = local.s3_data_lake_bucket_name
      Environment = terraform.workspace
    }
  )

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "iot_turntable_data_lake" {
  bucket = aws_s3_bucket.iot_turntable_data_lake.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "iot_turntable_data_lake" {
  bucket = aws_s3_bucket.iot_turntable_data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "iot_turntable_data_lake" {
  depends_on = [
    aws_s3_bucket_ownership_controls.iot_turntable_data_lake,
    aws_s3_bucket_public_access_block.iot_turntable_data_lake,
  ]

  bucket = aws_s3_bucket.iot_turntable_data_lake.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "iot_turntable_data_lake" {
  bucket = aws_s3_bucket.iot_turntable_data_lake.id
  versioning_configuration {
    status = "Disabled"
  }
}

#####################################################
# S3 Bucket for Athena Query Results
#####################################################
resource "aws_s3_bucket" "athena_query_results" {
  bucket        = local.s3_athena_results_bucket_name
  force_destroy = false

  tags = merge(
    var.default_tags,
    {
      Name        = local.s3_athena_results_bucket_name
      Environment = terraform.workspace
    }
  )

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "athena_query_results" {
  depends_on = [
    aws_s3_bucket_ownership_controls.athena_query_results,
    aws_s3_bucket_public_access_block.athena_query_results,
  ]

  bucket = aws_s3_bucket.athena_query_results.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id
  versioning_configuration {
    status = "Disabled"
  }
}
