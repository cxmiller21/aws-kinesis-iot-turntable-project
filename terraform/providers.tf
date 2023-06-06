terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "cm-sdg-terraform-state-bucket"
    key    = "aws/kinesis-iot-turntable/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
