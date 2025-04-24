resource "fmc_access_policies" "fmc_access_policy" {
  name           = var.access_policy
  default_action = "PERMIT"
}

resource "null_resource" "Create_resource_group" {
  provisioner "local-exec" {
    command     = "az deployment sub create --location EastUS --template-file create-rg.json --parameters virtualNetworkResourceGroup='${var.virtualNetworkResourceGroup}'"
    working_dir = "${path.module}/azure-arm"
  }
}

resource "null_resource" "Deploy_ARM_template" {
  depends_on = [null_resource.Create_resource_group]
  provisioner "local-exec" {
    command     = "az deployment group create --name acme-deployment --resource-group ${var.virtualNetworkResourceGroup} --template-file og-arm.json --parameters og-arm-parameter.json"
    working_dir = "${path.module}/azure-arm"
  }
}

resource "time_sleep" "wait_10_mins" {
  depends_on      = [null_resource.Deploy_ARM_template]
  create_duration = "10m"
}

resource "cdo_ftd_device" "ftd" {
  depends_on         = [fmc_access_policies.fmc_access_policy, time_sleep.wait_10_mins]
  name               = var.ftd_name
  licenses           = ["BASE"]
  virtual            = true
  performance_tier   = "FTDv50"
  access_policy_name = fmc_access_policies.fmc_access_policy.name
}

resource "null_resource" "print_arm_outputs" {
  depends_on = [cdo_ftd_device.ftd, null_resource.Deploy_ARM_template]
  provisioner "local-exec" {
    command     = <<EOT
    echo "Fetching public IPs from ARM deployment..."
    .venv/bin/python3 cdo.py --host $(az deployment group show --resource-group ${var.virtualNetworkResourceGroup} --name acme-deployment --query "properties.outputs.vmMgmtPublicIP.value" -o tsv | tr -d '\r\n') --username admin --password Cisco@123 --gen_command '${cdo_ftd_device.ftd.generated_command}'
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

## Onboarding the deployed FTD1
resource "cdo_ftd_device_onboarding" "ftd1" {
  ftd_uid    = cdo_ftd_device.ftd.id
  depends_on = [cdo_ftd_device.ftd, null_resource.print_arm_outputs]
}
resource "time_sleep" "wait_for_initial_deployment" {
  depends_on      = [cdo_ftd_device_onboarding.ftd1]
  create_duration = "5m"
}

## Add the config code here...
resource "null_resource" "configuration_apply" {
  depends_on = [time_sleep.wait_for_initial_deployment]

  provisioner "local-exec" {
    command     = "terraform init && terraform apply -auto-approve -var='cdo_token=${var.cdo_token}' -var='cdfmc_host=${var.cdfmc_host}' -var='access_policy=${var.access_policy}' -var='ftd_name=${var.ftd_name}'"
    working_dir = "${path.module}/config"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm terraform.tfstate*"
    working_dir = "${path.module}/config"
  }
}
