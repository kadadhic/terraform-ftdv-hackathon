## AWS module for default configuration

This directory contains terraform code for deploying
a FTD instance and a FMC (if needed) on AWS with an inside machine.
Terraform will proceed to run the configuration code
that will create the following on the FMC:

- inside and outside security zones
- Corporate-Lan and outside-gw network objects
- An Access policy with an "Allow All" access rule.
- A NAT Policy with a inside subnet to interface NAT rule.
- Registers the device and configures it with physical interfaces and static routes.
- Deploys the created configuration.
