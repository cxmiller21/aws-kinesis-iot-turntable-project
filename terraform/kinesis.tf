locals {
  kinesis_stream_name   = "${local.project_prefix}-stream"
  kinesis_firehose_name = "${local.project_prefix}-firehose"
}

#####################################################
# Kinesis Data Stream for IoT Turntable Applications
#####################################################
resource "aws_kinesis_stream" "iot_turntable" {
  name = local.kinesis_stream_name
  # shard_count      = 1
  retention_period = 24

  # https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = merge(
    var.default_tags,
    {
      Name        = "${local.kinesis_stream_name}"
      Environment = terraform.workspace
    }
  )
}

#####################################################
# Kinesis Firehose - Send KDS Events to S3
#####################################################
resource "aws_cloudwatch_log_group" "iot_turntable_firehose" {
  name              = "/aws/kinesisfirehose/${local.kinesis_firehose_name}"
  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "iot_turntable_s3_stream" {
  name        = local.kinesis_firehose_name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.iot_turntable.arn
    role_arn           = aws_iam_role.iot_turntable_firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.iot_turntable_firehose.arn
    bucket_arn = aws_s3_bucket.iot_turntable_data_lake.arn

    error_output_prefix = "errors/"
    s3_backup_mode      = "Disabled"

    buffer_size        = 64
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.iot_turntable_firehose.name
      log_stream_name = "DestinationDelivery"
    }

    data_format_conversion_configuration {
      enabled = true
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive                         = true
            column_to_json_key_mappings              = {}
            convert_dots_in_json_keys_to_underscores = true
          }
        }
      }

      output_format_configuration {
        serializer {
          orc_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.iot_turntable_catalog_table.database_name
        role_arn      = aws_iam_role.iot_turntable_firehose.arn
        table_name    = aws_glue_catalog_table.iot_turntable_catalog_table.name
      }
    }

    processing_configuration {
      enabled = "false"

      # processors {
      #   type = "Lambda"

      #   parameters {
      #     parameter_name  = "LambdaArn"
      #     parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
      #   }
      # }
    }
  }

  # server_side_encryption {
  #   enabled = false
  #   key_type = "AWS_OWNED_CMK"
  # }

  depends_on = [
    aws_iam_role_policy_attachment.iot_turntable,
    aws_iam_role.iot_turntable_firehose,
    aws_s3_bucket.iot_turntable_data_lake,
    aws_cloudwatch_log_group.iot_turntable_firehose,
  ]
}

#####################################################
# IAM Role and Policy for Kinesis Firehose
#####################################################
data "aws_iam_policy_document" "iot_turntable_firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "iot_turntable_firehose_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:database/*", # TODO update
      "arn:aws:glue:${var.aws_region}:${local.account_id}:table/*"     # TODO update
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetSchemaByDefinition"
    ]

    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:registry/*",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:schema/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetSchemaVersion"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_data_lake_bucket_name}",
      "arn:aws:s3:::${local.s3_data_lake_bucket_name}/*"
    ]
  }

  # Placeholder for Lambda to transform data
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${local.account_id}:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
  }

  # Placeholder for KMS actions
  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${local.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.us-east-1.amazonaws.com"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*",
        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/kinesisfirehose/KDS-S3-djXKA:log-stream:*",
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%:log-stream:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${local.account_id}:stream/${local.kinesis_stream_name}"
    ]
  }

  # Placeholder for KMS actions
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${local.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ViaService"
      values   = ["kinesis.us-east-1.amazonaws.com"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:EncryptionContext:aws:kinesis:arn"
      values = [
        "arn:aws:kinesis:${var.aws_region}:${local.account_id}:stream/${local.kinesis_stream_name}"
      ]
    }
  }
}

resource "aws_iam_policy" "iot_turntable_firehose" {
  name        = "${local.project_prefix}-firehose-policy"
  path        = "/"
  description = "IAM policy for IoT Turntable Kinesis Firehose"
  policy      = data.aws_iam_policy_document.iot_turntable_firehose_permissions.json
}

resource "aws_iam_role_policy_attachment" "iot_turntable" {
  role       = aws_iam_role.iot_turntable_firehose.name
  policy_arn = aws_iam_policy.iot_turntable_firehose.arn
}

resource "aws_iam_role" "iot_turntable_firehose" {
  name               = "${local.project_prefix}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.iot_turntable_firehose_assume_role.json
}
