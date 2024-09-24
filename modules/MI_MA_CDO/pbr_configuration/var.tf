variable "fmc_host" {
    type = string
    default = ""
}

variable "fmc_username" {
  default = "admin"
}
variable "ftd_ip1" {
}
variable "ftd_ip2" {
}
variable "cdo_host" {
}
variable "cdo_region" { 
}
variable "fmc_password" {
  default = "Cisco@123"
}
variable "cdo_token" {
  type        = string
  description = "CDO Token"
}