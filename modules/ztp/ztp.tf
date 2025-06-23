data "fmc_access_policies" "acp" {
    name = var.access_policy_name
}

resource "null_resource" "ztp" {
  provisioner "local-exec" {
    command = "python3 ${path.module}/ztp.py --host ${var.cdo_host} --token ${var.cdo_token} --password ${var.password} --acp ${data.fmc_access_policies.acp.id} --serial ${var.serial_numbers}"
  }
}

resource "null_resource" "delete_device" {
  triggers = {
    cdo_token  = var.cdo_token
    cdo_host = var.cdo_host
    serial_numbers = var.serial_numbers
  }

  provisioner "local-exec" {
    when    = destroy
    command = "python3 ${path.module}/delete.py --host ${self.triggers.cdo_host} --token ${self.triggers.cdo_token} --serial ${self.triggers.serial_numbers}"
  }
}