
# output "SSH_Command_FTD" {
#   value = "ssh -i ${var.prefix}-${var.keyname} admin@${module.service_network.aws_ftd_eip}"
# }

output "CDFMC_URL" {
  value = "https://${var.fmc_host}"
}

output "Bastion_URL" {
  value = "ssh ubuntu@${aws_instance.testLinux.public_ip}"
}
