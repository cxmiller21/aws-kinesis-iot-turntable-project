locals {
  athena_data_catalog_name = "IoTTurntableDataCatalog"
}

#####################################################
# Athena Resources for Querying and Analyzing IoT Turntable Data
#####################################################
resource "aws_athena_data_catalog" "example" {
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
