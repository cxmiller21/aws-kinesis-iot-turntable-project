variable "profile" {
  type    = string
  default = "default"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "aws-kinesis-iot-turntable"
}

variable "default_tags" {
  type = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "aws-kinesis-iot-turntable"
  }
}
