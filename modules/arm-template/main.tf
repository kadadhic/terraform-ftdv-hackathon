resource "fmc_access_policies" "fmc_access_policy" {
  name           = "Test-access-policy"
  default_action = "PERMIT"
}

resource "cdo_ftd_device" "ftd" {
  depends_on         = [fmc_access_policies.fmc_access_policy]
  name               = var.ftd_name
  licenses           = ["BASE"]
  virtual            = true
  performance_tier   = "FTDv50"
  access_policy_name = fmc_access_policies.fmc_access_policy.name
}

resource "null_resource" "run_ARM_templates" {
  provisioner "local-exec" {
    command = <<EOT
    az deployment sub create --location EastUS --template-file create-rg.json --parameters virtualNetworkResourceGroup='teande-acme-rg'
    az deployment group create --name acme-deployment --resource-group teande-acme-rg --template-file og-arm.json --parameters og-arm-parameter.json
    EOT
  }
}


resource "null_resource" "print_arm_outputs" {
  provisioner "local-exec" {
    command     = <<EOT
    echo "Fetching public IPs from ARM deployment..."
    python3 cdo.py --host $(az deployment group show --resource-group teande-acme-rg --name acme-deployment --query "properties.outputs.vmMgmtPublicIP.value" -o tsv | tr -d '\r\n') --username admin --password Cisco@123 --gen_command '${cdo_ftd_device.ftd.generated_command}'
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

## Add the arm template code here...


## Onboarding the deployed FTD1
resource "cdo_ftd_device_onboarding" "ftd1" {
  ftd_uid    = cdo_ftd_device.ftd.id
  depends_on = [cdo_ftd_device.ftd]
}
resource "time_sleep" "wait_10_secs" {
  depends_on      = [cdo_ftd_device_onboarding.ftd1]
  create_duration = "10s"
}

## Add the config code here...
# resource "null_resource" "pbr" {
#   depends_on = [time_sleep.wait_10_sec]

#   provisioner "local-exec" {
#     command     = "terraform init && terraform apply -auto-approve -var='fmc_host=${var.cdfmc_host}' -var='cdo_token=${var.cdo_token}' -var='cdo_host=${local.www_cdo_host}' "
#     working_dir = "${path.module}/config"
#   }

#   provisioner "local-exec" {
#     when        = destroy
#     command     = "rm terraform.tfstate*"
#     working_dir = "${path.module}/config"
#   }
# }
