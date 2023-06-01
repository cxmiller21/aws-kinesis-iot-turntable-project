locals {
  glue_table_name = replace("${local.project_prefix}-catalog-table", "-", "_")
}

#####################################################
# Glue Resources for Athena Data Catalog
#####################################################
resource "aws_glue_crawler" "iot_turntable_crawler" {
  database_name = aws_glue_catalog_database.iot_turntable_catalog_database.name
  name          = "${local.project_prefix}-crawler"
  role          = "arn:aws:iam::${local.account_id}:role/service-role/AWSGlueServiceRole-tf-import-test"

  table_prefix = replace("${local.project_prefix}-", "-", "_")

  s3_target {
    path = "s3://${aws_s3_bucket.iot_turntable_data_lake.bucket}"

    exclusions = [
      "errors/**",
    ]
  }
}

resource "aws_glue_catalog_database" "iot_turntable_catalog_database" {
  name       = "${local.project_prefix}-database"
  catalog_id = local.account_id

  # target_database {
  #   catalog_id = local.account_id
  #   database_name = aws_athena_database.iot_turntable.name
  # }

  # depends_on = [
  #   aws_athena_database.iot_turntable
  # ]
}

# The Glue Crawler will also create a table in the Glue Data Catalog
# This is for reference as well as MVP use for Terraform to spin up a usable application
resource "aws_glue_catalog_table" "iot_turntable_catalog_table" {
  name          = replace("${local.project_prefix}-non-crawler-2023", "-", "_")
  database_name = aws_glue_catalog_database.iot_turntable_catalog_database.name
  owner         = "owner"

  table_type = "EXTERNAL_TABLE"
  retention  = 0

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
      name       = "user_wifi_speed"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "user_ip_address"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user_local_latlng"
      parameters = {}
      type       = "string"
    }
  }
}
