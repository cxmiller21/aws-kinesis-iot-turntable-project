locals {
  athena_data_catalog_name = "IoTTurntableDataCatalog"
  named_query_prefix       = "${var.project_name}-reporting"
}

#####################################################
# Athena Resources for Querying and Analyzing IoT Turntable Data
#####################################################
resource "aws_athena_data_catalog" "iot_turntable" {
  name        = local.athena_data_catalog_name
  description = "Athena Glue based Data Catalog"
  type        = "GLUE"

  parameters = {
    "catalog-id" = local.account_id
  }

  tags = merge(
    var.default_tags,
    {
      Name        = local.athena_data_catalog_name
      Environment = terraform.workspace
    }
  )
}

#####################################################
# Athena Named Queries for Querying and Analyzing IoT Turntable Data
#####################################################
resource "aws_athena_named_query" "top_10_mau" {
  name        = "${local.named_query_prefix}-top-10-mau"
  description = "Get the top 10 most active IoT Turntable users"
  database    = local.glue_database_name
  workgroup   = "primary"

  query = <<EOT
SELECT turntableId, user_name, COUNT(*) as listen_count
FROM ${local.glue_crawler_table_name}
GROUP BY turntableId, user_name
Order by listen_count DESC
LIMIT 10;
EOT
}

resource "aws_athena_named_query" "rpm_percentage" {
  name        = "${local.named_query_prefix}-rpm-percentage"
  description = "Get the RPM percent for IoT Turntable events"
  database    = local.glue_database_name
  workgroup   = "primary"

  query = <<EOT
SELECT
    rpm,
    COUNT(*) AS total_count,
    (COUNT(*) / CAST((
        SELECT COUNT(*)
        FROM ${local.glue_crawler_table_name}
    ) AS decimal(10,2))) * 100 AS percentage
FROM ${local.glue_crawler_table_name}
GROUP BY rpm
LIMIT 10;
EOT
}

resource "aws_athena_named_query" "volume_counts" {
  name        = "${local.named_query_prefix}-volume-counts"
  description = "Get count of volume levels listened to by users. Range 0 to 100"
  database    = local.glue_database_name
  workgroup   = "primary"

  query = <<EOT
SELECT
    volume,
    COUNT(volume) AS total_count
FROM ${local.glue_crawler_table_name}
GROUP BY volume
ORDER BY total_count desc;
EOT
}
