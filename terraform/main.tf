resource "aws_kinesis_stream" "main" {
  name             = "${var.project_name}-stream"
  shard_count      = 1
  retention_period = 24

  # https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = var.default_tags
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
