variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  type = string
  default = "iot-turntable"
}

variable "sns_subscription_emails" {
  type      = string
  sensitive = true
  default   = "example@example.com" # Update with your email
}

variable "default_tags" {
  type = map(string)
  default = {
    Terraform = "true"
    Project   = "iot-turntable"
  }
}

variable "glue_table_columns" {
  type = map(object({
    name    = string
    comment = string
    type    = string
  }))
  # Terraform will not apply these in order (I'm not sure why but could be missing how to fix it)
  default = {
    "turntableid" = {
      name    = "turntableid"
      comment = ""
      type    = "string"
    },
    "artist" = {
      name    = "artist"
      comment = ""
      type    = "string"
    },
    "album" = {
      name    = "album"
      comment = ""
      type    = "string"
    },
    "song" = {
      name    = "song"
      comment = ""
      type    = "string"
    },
    "play_timestamp" = {
      name    = "play_timestamp"
      comment = ""
      type    = "string"
    },
    "rpm" = {
      name    = "rpm"
      comment = ""
      type    = "int"
    },
    "volume" = {
      name    = "volume"
      comment = ""
      type    = "int"
    },
    "speaker" = {
      name    = "speaker"
      comment = ""
      type    = "string"
    },
    "user_name" = {
      name    = "user_name"
      comment = ""
      type    = "string"
    },
    "user_email" = {
      name    = "user_email"
      comment = ""
      type    = "string"
    },
    "user_zip_code" = {
      name    = "user_zip_code"
      comment = ""
      type    = "string"
    },
    "user_wifi_name" = {
      name    = "user_wifi_name"
      comment = ""
      type    = "string"
    },
    "user_wifi_mbps" = {
      name    = "user_wifi_mbps"
      comment = ""
      type    = "string"
    },
    "user_ip_address" = {
      name    = "user_ip_address"
      comment = ""
      type    = "string"
    },
    "user_latitude" = {
      name    = "user_latitude"
      comment = ""
      type    = "string"
    },
    "user_longitude" = {
      name    = "user_longitude"
      comment = ""
      type    = "string"
    },
    "user_iso_code" = {
      name    = "user_iso_code"
      comment = ""
      type    = "string"
    }
  }
}
