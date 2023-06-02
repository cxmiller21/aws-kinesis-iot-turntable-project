locals {
  reporting_prefix      = "${local.project_prefix}-reporting"
  reporting_lambda_name = "${local.reporting_prefix}-lambda"
  lambda_iam_role_name  = "${local.reporting_prefix}-lambda-role"
}

######################################################
# CloudWatch Logs
######################################################
resource "aws_cloudwatch_log_group" "reporting_lambda" {
  name              = "/aws/lambda/${local.reporting_lambda_name}"
  retention_in_days = 3
}

######################################################
# EventBridge (TODO: Enable when ready to create cron)
######################################################
/*
resource "aws_cloudwatch_event_bus" "reporting" {
  name = "${local.project_prefix}-event-bus"
}

resource "aws_cloudwatch_event_rule" "reporting_lambda" {
  name           = "${local.reporting_prefix}-rule"
  event_bus_name = aws_cloudwatch_event_bus.reporting.name
  event_pattern = jsonencode(
    {
      "source" : [ "payment-service" ]
    }
  )
}

resource "aws_cloudwatch_event_target" "reporting_lambda" {
  rule           = aws_cloudwatch_event_rule.reporting_lambda.name
  arn            = aws_lambda_function.reporting_lambda.arn
  event_bus_name = aws_cloudwatch_event_bus.reporting.name
}
*/

######################################################
# Lambda Function
######################################################
data "archive_file" "reporting_lambda" {
  type             = "zip"
  source_file      = "${path.module}/../application/reporting-service/generate_report.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/generate_report.py.zip"
}

# resource "aws_lambda_permission" "reporting_lambda" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.reporting_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.reporting_lambda.arn
# }

resource "aws_lambda_function" "reporting_lambda" {
  filename      = "${path.module}/generate_report.py.zip"
  function_name = local.reporting_lambda_name
  role          = aws_iam_role.reporting_service_lambda_role.arn
  handler       = "generate_report.lambda_handler"
  runtime       = "python3.10"
  timeout       = 300

  environment {
    variables = {
      ATHENA_S3_REPORTING_BUCKET = aws_s3_bucket.athena_query_results.id
      GLUE_DATABASE_NAME         = aws_glue_catalog_database.iot_turntable_catalog_database.name
      GLUE_DATABASE_TABLE        = aws_glue_catalog_table.iot_turntable_catalog_table.name
      # EVENT_BUS_NAME = aws_cloudwatch_event_bus.reporting.name
    }
  }

  source_code_hash = data.archive_file.reporting_lambda.output_base64sha256

  depends_on = [
    # aws_cloudwatch_event_bus.reporting,
    aws_cloudwatch_log_group.reporting_lambda,
    aws_iam_role.reporting_service_lambda_role
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

  # statement {
  #   effect = "Allow"

  #   actions = [
  #     "events:PutEvents",
  #   ]

  #   resources = ["arn:aws:events:${var.aws_region}:${local.account_id}:event-bus/${aws_cloudwatch_event_bus.reporting.name}"]
  # }

  statement {
    effect = "Allow"

    actions = [
      "SNS:Publish",
    ]

    resources = ["arn:aws:sns:${var.aws_region}:${local.account_id}:${local.reporting_prefix}*"]
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
      "athena:GetQueryExecution"
    ]

    resources = ["arn:aws:athena:${var.aws_region}:${local.account_id}:workgroup/primary"]
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
      "arn:aws:s3:::${local.s3_athena_results_bucket_name}/*"
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
