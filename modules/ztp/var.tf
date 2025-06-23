variable "cdo_token" {
  type        = string
  description = "CDO Token"
}
variable "cdo_host" {
  type        = string
  description = "This is the URL you enter when logging into your CDO account"
}
variable "cdfmc_host" {
  type        = string
  description = "cdFMC host domain name(meaning without https://)"
}
variable "access_policy_name" {
  type = string
  description = "Name of the access policy"
  default = "Default Access Control Policy" 
}
variable "password" {
  type = string
  description = "Change password of the FTDs"
}
variable "serial_numbers" {
  type = string
  description = "Comma separated serial numbers of the FTDs (no spaces)"
}