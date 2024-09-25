# Copyright (c) 2022 Cisco Systems, Inc. and its affiliates
# All rights reserved.

data "aws_ami" "ftdv" {
  most_recent = true
  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["${var.ftd_version}*"]
  }

  # filter {
  #   name   = "product-code"
  #   values = ["a8sxy6easi2zumgtyr564z6y7"]
  # }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "ftd_startup_file" {
  count = 2
  template = file("${path.module}/ftd_startup_file.txt")
  vars = {
    fmc_ip     = var.fmc_host
    reg_key    = var.reg_key[count.index]
    ftd_admin_password = var.ftd_admin_password
    nat_id = var.nat_id[count.index]
  }
}
