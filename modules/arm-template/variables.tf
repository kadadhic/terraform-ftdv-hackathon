# variable "aws_access_key" {
#   type        = string
#   description = "AWS ACCESS KEY"
#   default = ""
# }

# variable "aws_secret_key" {
#   type        = string
#   description = "AWS SECRET KEY"
#   default = ""
# }
variable "prefix" {
  type    = string
  default = "Fireglass"
}

########################################################################
## Instances
########################################################################

variable "ftd_size" {
  type        = string
  description = "FTD Instance Size"
  default     = "c5a.4xlarge"
}

variable "keyname" {
  type        = string
  description = "key to be used for the instances"
  default     = "fireglass-key"
}


variable "reg_key" {
  type        = list(string)
  description = "FTD registration key"
  default     = ["cisco", "cisco"]
}

variable "nat_id" {
  type        = list(string)
  description = "NAT ID of the FTD"
  default     = ["", ""]
}
variable "cdfmc_host" {
  type        = string
  description = "cdFMC host domain name(meaning without https://)"
}
variable "cdo_token" {
  type        = string
  description = "CDO Token"
}

variable "cdo_host" {
  type        = string
  description = "This is the URL you enter when logging into your CDO account"
}

variable "ftd_name" {
  type        = string
  description = "This will be the name of the FTD that shows up in the cdFMC"
  default     = "FTD"
}

variable "virtualNetworkResourceGroup" {
  type    = string
  default = "arm-ftdv-rg"
}

variable "access_policy" {
  type    = string
  default = "arm-access-policy"
}
