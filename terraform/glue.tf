locals {
  glue_database_name = "${local.project_prefix}-database"
  glue_crawler_name  = "${local.project_prefix}-crawler"
  glue_table_name    = replace("${local.project_prefix}-non-crawler-2023", "-", "_")
}

#####################################################
# Glue Resources for Athena Data Catalog
#####################################################
resource "aws_glue_crawler" "iot_turntable_crawler" {
  database_name = aws_glue_catalog_database.iot_turntable_catalog_database.name
  name          = local.glue_crawler_name
  role = aws_iam_role.glue_crawler.arn

  table_prefix = ""

  s3_target {
    path = "s3://${aws_s3_bucket.iot_turntable_data_lake.bucket}"

    exclusions = [
      "errors/**",
    ]
  }

  tags = merge(
    var.default_tags,
    {
      "Name"        = local.glue_crawler_name
      "Environment" = terraform.workspace
    }
  )
}

resource "aws_glue_catalog_database" "iot_turntable_catalog_database" {
  name       = local.glue_database_name
  catalog_id = local.account_id

  tags = merge(
    var.default_tags,
    {
      "Name"        = local.glue_database_name
      "Environment" = terraform.workspace
    }
  )
}

# The Glue Crawler will create a similar table to this one that we'll use to query
# We need this table for Kinesis to reference and use the Schema to transform records
resource "aws_glue_catalog_table" "iot_turntable_catalog_table" {
  name          = local.glue_table_name
  database_name = aws_glue_catalog_database.iot_turntable_catalog_database.name
  owner         = "owner"

  table_type = "EXTERNAL_TABLE"
  retention  = 0

  parameters = {
    "compressionType" = "none"
    "classification"  = "orc"
    "typeOfData"      = "file"
  }

  partition_index {
    index_name = "year_month_day_hour"
    # index_status = "ACTIVE"
    keys = ["month", "day", "hour"]
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  partition_keys {
    name = "hour"
    type = "string"
  }

  storage_descriptor {
    input_format      = "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat"
    number_of_buckets = -1
    output_format     = "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat"

    location = "s3://${local.s3_data_lake_bucket_name}/2023/"

    bucket_columns            = []
    compressed                = false
    stored_as_sub_directories = false

    parameters = {}

    ser_de_info {
      parameters            = {}
      serialization_library = "org.apache.hadoop.hive.ql.io.orc.OrcSerde"
    }

    dynamic "columns" {
      for_each = var.glue_table_columns
      content {
        name    = columns.value.name
        comment = columns.value.comment
        type    = columns.value.type
      }
    }

    /*
    # Temporarily keeping this here for reference of column order
    # For some reason the dynamic option isn't creating in order
    columns {
      name       = "turntableid"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "artist"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "album"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "song"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "play_timestamp"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "rpm"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "volume"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "speaker"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_name"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_email"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_zip_code"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_wifi_name"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_wifi_mbps"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "user_ip_address"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_latitude"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_longitude"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_iso_code"
      parameters = {}
      type       = "string"
    }
    */
  }
}

#####################################################
# IAM Role and Policy for Glue Crawler
#####################################################
data "aws_iam_policy_document" "glue_crawler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "glue_crawler_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:*",
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
      "glue:*",
    ]

    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:registry/*",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:schema/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketAcl",
      "s3:PutObject",
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
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws-glue/*",
    ]
  }
}

resource "aws_iam_policy" "glue_crawler" {
  name        = "${local.glue_crawler_name}-policy"
  path        = "/"
  description = "IAM policy for IoT Turntable Glue Crawler"
  policy      = data.aws_iam_policy_document.glue_crawler_permissions.json

  tags = merge(
    var.default_tags,
    {
      "Name"        = "${local.glue_crawler_name}-policy"
      "Environment" = terraform.workspace
    }
  )
}

resource "aws_iam_role_policy_attachment" "glue_crawler" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = aws_iam_policy.glue_crawler.arn
}

resource "aws_iam_role" "glue_crawler" {
  name               = "${local.glue_crawler_name}-role"
  assume_role_policy = data.aws_iam_policy_document.glue_crawler_assume_role.json

  tags = merge(
    var.default_tags,
    {
      "Name"        = "${local.glue_crawler_name}-role"
      "Environment" = terraform.workspace
    }
  )
}
