terraform {
  required_providers {
    aws = {
      version =  "~> 4.0"
      source  = "hashicorp/aws"
    }
    fmc = {
      source = "CiscoDevnet/fmc"
    }
  }
}

provider "aws" {
  region     = var.region
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}


provider "fmc" {
  fmc_username             = var.fmc_username
  fmc_password             = var.fmc_password
  fmc_host                 = module.service_network.FMC_public_ip
  fmc_insecure_skip_verify = true
}
