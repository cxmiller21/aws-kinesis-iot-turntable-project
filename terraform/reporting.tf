locals {
  reporting_prefix          = "${local.project_prefix}-reporting"
  reporting_s3_bucket_name  = "${local.project_prefix}-${random_string.bucket_suffix.id}-reports"
  reporting_lambda_name     = "${local.reporting_prefix}-lambda"
  lambda_iam_role_name      = "${local.reporting_prefix}-lambda-role"
  cloudwatch_event_bus_name = "default" # required for scheduled events...
}

######################################################
# CloudWatch Logs
######################################################
resource "aws_cloudwatch_log_group" "reporting_lambda" {
  name              = "/aws/lambda/${local.reporting_lambda_name}"
  retention_in_days = 3
}

######################################################
# EventBridge Scheduled Events
######################################################
data "aws_iam_policy_document" "scheduler_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.project_prefix}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_role.json
  tags               = var.default_tags
}

data "aws_iam_policy_document" "schduler_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "arn:aws:lambda:${var.aws_region}:${local.account_id}:function:${local.reporting_lambda_name}*",
    ]
  }
}

resource "aws_iam_policy" "scheduler" {
  name        = "${local.project_prefix}-eventbridge-schdeuler-policy"
  path        = "/"
  description = "IAM policy for invoking a lambda function from an EventBridge schedule"
  policy      = data.aws_iam_policy_document.schduler_policy.json
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}

resource "aws_scheduler_schedule_group" "reporting_service" {
  name = "${local.project_prefix}-group"
  tags = var.default_tags
}

resource "aws_scheduler_schedule" "reporting_service" {
  name       = "${local.project_prefix}-schedule"
  group_name = aws_scheduler_schedule_group.reporting_service.name

  flexible_time_window {
    # maximum_window_in_minutes = 15
    mode = "OFF"
  }

  schedule_expression          = "cron(0 10 1 * ? *)"
  schedule_expression_timezone = "America/Chicago"
  state                        = "ENABLED"

  target {
    arn      = aws_lambda_function.reporting_lambda.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 3
    }
  }

  depends_on = [
    aws_iam_role.scheduler,
    aws_lambda_function.reporting_lambda,
  ]
}

#####################################################
# S3 Bucket for Generated Report Results
#####################################################
resource "aws_s3_bucket" "reporting_results" {
  bucket        = local.reporting_s3_bucket_name
  force_destroy = false

  tags = merge(
    var.default_tags,
    {
      Name        = local.reporting_s3_bucket_name
      Environment = terraform.workspace
    }
  )

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "reporting_results" {
  bucket = aws_s3_bucket.reporting_results.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "reporting_results" {
  bucket = aws_s3_bucket.reporting_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "reporting_results" {
  depends_on = [
    aws_s3_bucket_ownership_controls.reporting_results,
    aws_s3_bucket_public_access_block.reporting_results,
  ]

  bucket = aws_s3_bucket.reporting_results.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "reporting_results" {
  bucket = aws_s3_bucket.reporting_results.id
  versioning_configuration {
    status = "Disabled"
  }
}

######################################################
# Lambda Function
######################################################
data "archive_file" "reporting_lambda" {
  type             = "zip"
  source_file      = "${path.module}/../application/reporting-service/generate_report.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/generate_report.py.zip"
}

resource "aws_lambda_function" "reporting_lambda" {
  filename      = "${path.module}/generate_report.py.zip"
  function_name = local.reporting_lambda_name
  role          = aws_iam_role.reporting_service_lambda_role.arn
  handler       = "generate_report.lambda_handler"
  runtime       = "python3.10"
  timeout       = 300

  environment {
    variables = {
      ATHENA_S3_REPORTING_BUCKET      = aws_s3_bucket.athena_query_results.id
      ATHENA_S3_REPORTING_PATH        = "reporting-service/"
      ATHENA_NAMED_QUERY_PREFIX       = local.named_query_prefix
      REPORTING_SERVICE_S3_BUCKET     = aws_s3_bucket.reporting_results.id
      REPORTING_SERVICE_SNS_TOPIC_ARN = aws_sns_topic.reporting_service.arn
      GLUE_DATABASE_NAME              = aws_glue_catalog_database.iot_turntable_catalog_database.name
      GLUE_DATABASE_TABLE             = aws_glue_catalog_table.iot_turntable_catalog_table.name
      EVENT_BUS_NAME                  = local.cloudwatch_event_bus_name
    }
  }

  source_code_hash = data.archive_file.reporting_lambda.output_base64sha256

  depends_on = [
    aws_cloudwatch_log_group.reporting_lambda,
    aws_iam_role.reporting_service_lambda_role,
    aws_s3_bucket.reporting_results,
    aws_sns_topic.reporting_service
  ]
}

data "aws_iam_policy_document" "reporting_service_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "reporting_service_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]

    resources = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/TBD"]
  }

  statement {
    effect = "Allow"

    actions = [
      "events:PutEvents",
    ]

    resources = ["arn:aws:events:${var.aws_region}:${local.account_id}:event-bus/${local.cloudwatch_event_bus_name}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "SNS:Publish",
    ]

    resources = ["arn:aws:sns:${var.aws_region}:${local.account_id}:${local.reporting_prefix}-topic"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.reporting_lambda_name}:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartitions",
    ]

    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:table/${local.project_prefix}*",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:database/${local.project_prefix}*",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:catalog"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryExecution",
      "athena:ListNamedQueries",
      "athena:GetNamedQuery",
    ]

    resources = ["arn:aws:athena:${var.aws_region}:${local.account_id}:workgroup/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_data_lake_bucket_name}",
      "arn:aws:s3:::${local.s3_data_lake_bucket_name}/*",
      "arn:aws:s3:::${local.s3_athena_results_bucket_name}",
      "arn:aws:s3:::${local.s3_athena_results_bucket_name}/*",
      "arn:aws:s3:::${local.reporting_s3_bucket_name}",
      "arn:aws:s3:::${local.reporting_s3_bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "reporting_service_lambda" {
  name        = "${local.reporting_prefix}-lambda-policy"
  path        = "/"
  description = "IAM policy for Reporting Service Lambda functions"
  policy      = data.aws_iam_policy_document.reporting_service_lambda.json
}

resource "aws_iam_role_policy_attachment" "reporting_service_lambda" {
  role       = aws_iam_role.reporting_service_lambda_role.name
  policy_arn = aws_iam_policy.reporting_service_lambda.arn
}

resource "aws_iam_role" "reporting_service_lambda_role" {
  name               = "${local.reporting_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.reporting_service_lambda_assume_role.json
}
######################################################
# SNS Lambda Topic and Subscription
######################################################
resource "aws_sns_topic" "reporting_service" {
  name              = "${local.reporting_prefix}-topic"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.default_tags
}

resource "aws_sns_topic_subscription" "reporting_service" {
  topic_arn = aws_sns_topic.reporting_service.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_emails
}

resource "aws_sns_topic_policy" "reporting_service" {
  arn    = aws_sns_topic.reporting_service.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  version   = "2008-10-17"

  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.reporting_lambda.arn]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.reporting_service.arn,
    ]

    sid = "allow_lambda_to_publish_to_sns"
  }

  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [local.account_id]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.reporting_service.arn,
    ]

    sid = "allow_owner_to_manage_sns_topic"
  }
}
