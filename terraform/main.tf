data "aws_caller_identity" "current" {}

locals {
  account_id               = data.aws_caller_identity.current.account_id
  project_prefix           = "${var.project_name}-${terraform.workspace}"
  s3_data_lake_bucket_name = "${local.project_prefix}-data-lake"
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
    prevent_destroy = true
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
  bucket        = "${local.project_prefix}-athena-query-results"
  force_destroy = false

  tags = merge(
    var.default_tags,
    {
      Name        = "${local.project_prefix}-athena-query-results"
      Environment = terraform.workspace
    }
  )

  lifecycle {
    prevent_destroy = true
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

/*
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "KinesisTestInstance"

  ami                    = "ami-0b0dcb5067f052a63"
  instance_type          = "t2.micro"
  key_name               = "kinesis-keypair"
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.main.id]
  # subnet_id              = "subnet-eddcdzz4"

  iam_instance_profile = aws_iam_instance_profile.kinesis.name

  user_data = <<EOF
#!/bin/bash
sudo yum update
sudo yum install -y aws-kinesis-agent
sudo service aws-kinesis-agent stop
sudo rm -f /etc/aws-kinesis/agent.json
sudo cat >/etc/aws-kinesis/agent.json <<EOL
{
  "cloudwatch.emitMetrics": true,
  "kinesis.endpoint": "",
  "firehose.endpoint": "",

  "flows": [
    {
      "filePattern": "/tmp/test.log",
      "kinesisStream": "aws-kinesis-stock-data-stream"
    }
  ]
}
EOL
sudo service aws-kinesis-agent start
cat >/tmp/test.log <<EOL
123.45.67.89 - - [27/Oct/2000:09:27:09 -0400] "GET /java/javaResources.html HTTP/1.0" 200
123.45.67.89 - - [27/Oct/2000:09:27:10 -0400] "GET /java/javaResources.html HTTP/1.0" 200
EOL
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "main" {
  bucket = var.project-name

  tags = {
    Name        = "${var.project-name}"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
*/
