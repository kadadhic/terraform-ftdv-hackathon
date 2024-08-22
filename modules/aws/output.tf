output "fmc_ip" {
  value = aws_eip.fmcmgmt-EIP.*.public_ip
}
output "ftd_ip" {
  value = aws_eip.ftd01mgmt-EIP.*.public_ip
}
# output "SSHCommand_FTD1" {
#   value = "ssh -i ciscoKeys admin@${aws_eip.ftd01mgmt-EIP.public_ip}"
# }
# output "SSHCommand_FTD2" {
#   value = "ssh -i ciscoKeys admin@${aws_eip.ftd02mgmt-EIP.public_ip}"
# }