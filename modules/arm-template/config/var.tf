variable "cdfmc_host" {
  type    = string
  default = ""
}

variable "fmc_username" {
  type    = string
  default = "admin"
}
variable "cdo_host" {
  type    = string
  default = ""
}
variable "fmc_password" {
  type    = string
  default = "Cisco@123"
}
variable "cdo_token" {
  type        = string
  description = "CDO Token"
}
variable "ftd_name" {
  type = string
}

variable "access_policy" {
  type = string
}
