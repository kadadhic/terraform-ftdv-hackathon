################################################################################################
terraform {
  required_providers {
    fmc = {
      source = "CiscoDevnet/fmc"
    }
  }
}

provider "fmc" {
  is_cdfmc                 = true
  cdo_token                = var.cdo_token
  fmc_host                 = var.cdfmc_host
  cdfmc_domain_uuid        = "e276abec-e0f2-11e3-8169-6d9ed49b625f"
  fmc_insecure_skip_verify = true
}

# ################################################################################################
# # Data blocks
# ################################################################################################
data "fmc_devices" "device01" {
  name = var.ftd_name
}
data "fmc_network_objects" "any-ipv4" {
  name = "any-ipv4"
}
#1st device
data "fmc_device_physical_interfaces" "zero_physical_interface_device01" {
  device_id = data.fmc_devices.device01.id
  name      = "GigabitEthernet0/0"
}
data "fmc_device_physical_interfaces" "one_physical_interface_device01" {
  device_id = data.fmc_devices.device01.id
  name      = "GigabitEthernet0/1"
}

################################################################################################
# Security Zones
################################################################################################
resource "fmc_security_zone" "inside" {
  name           = "InZone01"
  interface_mode = "ROUTED"
}
resource "fmc_security_zone" "outside01" {
  name           = "OutZone01"
  interface_mode = "ROUTED"
}

################################################################################################
# Network & Host Object
################################################################################################
resource "fmc_network_objects" "corporate-lan01" {
  name  = "Inside-subnet-01"
  value = "10.4.3.0/24"
}

resource "fmc_network_objects" "outside-subnet-01" {
  name  = "Outside-subnet-01"
  value = "10.4.2.0/24"
}

resource "fmc_host_objects" "outside01-gw" {
  name  = "Outside01-GW"
  value = "10.4.2.1"
}

################################################################################################
# Access Policy
################################################################################################
data "fmc_access_policies" "access_policy" {
  name = var.access_policy
}

resource "fmc_access_rules" "access_rule" {
  acp                = data.fmc_access_policies.access_policy.id
  section            = "mandatory"
  name               = "allow-out-in"
  action             = "allow"
  enabled            = true
  send_events_to_fmc = true
  log_end            = true
  source_zones {
    source_zone {
      id   = fmc_security_zone.outside01.id
      type = "SecurityZone"
    }
  }
  destination_zones {
    destination_zone {
      id   = fmc_security_zone.inside.id
      type = "SecurityZone"
    }
  }
  new_comments = ["Applied via terraform"]
}

################################################################################################
# Nat Policy
################################################################################################
resource "fmc_ftd_nat_policies" "nat_policy01" {
  name        = "NAT_Policy01"
  description = "Nat policy by terraform"
}

################################################################################################
# Configuring physical interfaces
################################################################################################
resource "fmc_device_physical_interfaces" "physical_interfaces00" {
  enabled                = true
  device_id              = data.fmc_devices.device01.id
  physical_interface_id  = data.fmc_device_physical_interfaces.zero_physical_interface_device01.id
  name                   = data.fmc_device_physical_interfaces.zero_physical_interface_device01.name
  security_zone_id       = fmc_security_zone.outside01.id
  if_name                = "outside01"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}
resource "fmc_device_physical_interfaces" "physical_interfaces01" {
  device_id              = data.fmc_devices.device01.id
  physical_interface_id  = data.fmc_device_physical_interfaces.one_physical_interface_device01.id
  name                   = data.fmc_device_physical_interfaces.one_physical_interface_device01.name
  security_zone_id       = fmc_security_zone.inside.id
  if_name                = "inside"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}

################################################################################################
# Adding static route
################################################################################################
resource "fmc_staticIPv4_route" "route01" {
  depends_on     = [data.fmc_devices.device01, fmc_device_physical_interfaces.physical_interfaces00]
  metric_value   = 25
  device_id      = data.fmc_devices.device01.id
  interface_name = "outside01"
  selected_networks {
    id   = data.fmc_network_objects.any-ipv4.id
    type = data.fmc_network_objects.any-ipv4.type
    name = data.fmc_network_objects.any-ipv4.name
  }
  gateway {
    object {
      id   = fmc_host_objects.outside01-gw.id
      type = fmc_host_objects.outside01-gw.type
      name = fmc_host_objects.outside01-gw.name
    }
  }
}

################################################################################################
# Attaching NAT Policy to device
################################################################################################
resource "fmc_policy_devices_assignments" "policy_assignment01" {
  depends_on = [fmc_staticIPv4_route.route01]
  policy {
    id   = fmc_ftd_nat_policies.nat_policy01.id
    type = fmc_ftd_nat_policies.nat_policy01.type
  }
  target_devices {
    id   = data.fmc_devices.device01.id
    type = data.fmc_devices.device01.type
  }
}

################################################################################################
# Deploying the changes to the device
################################################################################################
resource "fmc_ftd_deploy" "ftd01" {
  depends_on     = [fmc_policy_devices_assignments.policy_assignment01]
  device         = data.fmc_devices.device01.id
  ignore_warning = true
  force_deploy   = false
}
