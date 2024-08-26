output "FMC_URL" {
  value = "https://${aws_eip.fmcmgmt-EIP.public_ip}"
}
output "SSH_Command_FTD" {
  value = "ssh -i ${var.prefix}-${var.keyname} admin@${aws_eip.ftd01mgmt-EIP.public_ip}"
}
