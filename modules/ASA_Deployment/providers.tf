provider "aws" {
    region = var.region
    # access_key = var.aws_access_key
    # secret_key = var.aws_secret_key
}

terraform {
  required_version = ">= v1.3.2"
}