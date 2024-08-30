module "service_network" {
  source                = "./modules/network"
  vpc_cidr              = var.service_vpc_cidr
  vpc_name              = var.service_vpc_name
  create_igw            = var.service_create_igw
  mgmt_subnet_cidr      = var.mgmt_subnet_cidr
  ftd_mgmt_ip           = var.ftd_mgmt_ip
  outside_subnet_cidr   = var.outside_subnet_cidr
  ftd_outside_ip        = var.ftd_outside_ip
  diag_subnet_cidr      = var.diag_subnet_cidr
  ftd_diag_ip           = var.ftd_diag_ip
  inside_subnet_cidr    = var.inside_subnet_cidr
  ftd_inside_ip         = var.ftd_inside_ip
  fmc_ip                = var.fmc_ip
  mgmt_subnet_name      = var.mgmt_subnet_name
  outside_subnet_name   = var.outside_subnet_name
  diag_subnet_name      = var.diag_subnet_name
  inside_subnet_name    = var.inside_subnet_name
  outside_interface_sg  = var.outside_interface_sg
  inside_interface_sg   = var.inside_interface_sg
  mgmt_interface_sg     = var.mgmt_interface_sg
  fmc_mgmt_interface_sg = var.fmc_mgmt_interface_sg
  use_fmc_eip           = var.use_fmc_eip
  use_ftd_eip           = var.use_ftd_eip
  prefix = var.prefix
}

module "instance" {
  source                  = "./modules/firewall_instance"
  keyname                 = var.keyname
  ftd_size                = var.ftd_size
  instances_per_az        = var.instances_per_az
  availability_zone_count = var.availability_zone_count
  fmc_mgmt_ip             = var.fmc_ip
  ftd_mgmt_interface      = module.service_network.mgmt_interface
  ftd_inside_interface    = module.service_network.inside_interface
  ftd_outside_interface   = module.service_network.outside_interface
  ftd_diag_interface      = module.service_network.diag_interface
  fmcmgmt_interface       = module.service_network.fmcmgmt_interface
  reg_key                 = var.reg_key
  fmc_nat_id              = var.fmc_nat_id 
  create_fmc              = var.create_fmc
  prefix = var.prefix
}

#########################################################################################################
# Creation of Network Load Balancer
#########################################################################################################

resource "aws_lb" "external01_lb" {
  name                             = "${var.prefix}-External01-LB"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"
  subnets                          = module.service_network.outside_subnet
}

resource "aws_lb_target_group" "front_end1_1" {
  count       = length(var.listener_ports)
  name        = tostring("fe1-1-${lookup(var.listener_ports[count.index], "port", null)}")
  port        = lookup(var.listener_ports[count.index], "port", null)
  protocol    = lookup(var.listener_ports[count.index], "protocol", null)
  target_type = "ip"
  vpc_id      = module.service_network.vpc_id

  health_check {
    interval = 30
    protocol = var.health_check.protocol
    port     = var.health_check.port
  }
}

resource "aws_lb_listener" "listener1_1" {
  load_balancer_arn = aws_lb.external01_lb.arn
  count             = length(var.listener_ports)
  port              = lookup(var.listener_ports[count.index], "port", null)
  protocol          = lookup(var.listener_ports[count.index], "protocol", null)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end1_1[count.index].arn
  }
}

resource "aws_lb_target_group_attachment" "target1_1a" {
  count            = length(var.ftd_outside_ip)
  depends_on       = [aws_lb_target_group.front_end1_1]
  target_group_arn = aws_lb_target_group.front_end1_1[0].arn
  target_id        = var.ftd_outside_ip[count.index]
}

resource "aws_lb_target_group_attachment" "target1_1b" {
  count            = length(var.ftd_outside_ip)
  depends_on       = [aws_lb_target_group.front_end1_1]
  target_group_arn = aws_lb_target_group.front_end1_1[1].arn
  target_id        = var.ftd_outside_ip[count.index]
}

#########################################################################################################
# Creation of Extra Subnet - Outside 2 subnet
#########################################################################################################

data "aws_availability_zones" "available" {}

data "aws_vpc" "fireglass-vpc"{
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-FireGlass-VPC"]
  }
}

data "aws_security_group" "sg"{
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["Outside-InterfaceSG"]
  }
}

# data "aws_route_table" "route-table"{
#   filter {
#     name   = "tag:Name"
#     values = ["outside network Routing table"]
#   }
# }

variable "public_subnet_cidr" {
  default = ["172.16.5.0/24","172.16.15.0/24"]
}

variable "ftd_public_ip" {
  default = ["172.16.5.10","172.16.15.10"]
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = data.aws_vpc.fireglass-vpc.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.prefix}-Public-subnet-${count.index+1}"
  }
}

resource "aws_network_interface" "ftd_public" {
  count             = 2 //length(var.outside_interface) == 0 ? length(var.ftd_outside_ip) : 0
  description       = "asa${count.index}-public"
  subnet_id         = aws_subnet.public_subnet[count.index].id
  source_dest_check = false
  private_ips       = [var.ftd_public_ip[count.index]]
   security_groups   = [data.aws_security_group.sg.id]
}

resource "aws_route_table" "ftd_public_route" {
  count  = 2 //length(local.outside_subnet)
  vpc_id = data.aws_vpc.fireglass-vpc.id//local.con
  tags = {
    Name = "${var.prefix}-public network Routing table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.ftd_public_route[count.index].id
}

resource "aws_eip" "ftd_public_eip" {
  count = 2 //var.use_ftd_eip ? length(var.mgmt_subnet_name) : 0
  tags = {
    "Name" = "${var.prefix}-fireglass-ftd-${count.index} public IP"
  }
}

resource "aws_eip_association" "ftd_public_ip_assocation" {
  depends_on = [module.instance,module.service_network]
  count                = length(aws_eip.ftd_public_eip)
  network_interface_id = aws_network_interface.ftd_public[count.index].id
  allocation_id        = aws_eip.ftd_public_eip[count.index].id
}

#########################################################################################################
# Creation of Inside machine
#########################################################################################################

data "aws_subnet" "inside-subnet" {
depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-inside_subnet-1"]
  }
}

data "aws_security_group" "inside-sg"{
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-Inside-InterfaceSG"]
  }
}

resource "aws_network_interface" "ftd_app" {
  #count = length(var.dmz_subnet_cidr) != 0 ? length(var.dmz_subnet_cidr) : 0  ||  length(var.dmz_subnet_name) != 0 ? length(var.dmz_subnet_name) : 0
  # count             = length(var.app_interface) != 0 ? length(var.app_interface) : length(var.ftd_app_ip)
  description       = "app-nic"
  subnet_id         = data.aws_subnet.inside-subnet.id
  source_dest_check = false
  private_ips       = ["172.16.3.30"]
}

resource "aws_network_interface_sg_attachment" "ftd_app_attachment" {
  # count                = //length(var.app_interface) != 0 ? length(var.app_interface) : length(var.ftd_app_ip)
  depends_on           = [aws_network_interface.ftd_app]
  security_group_id    = data.aws_security_group.inside-sg.id
  network_interface_id = aws_network_interface.ftd_app.id
}

resource "aws_instance" "EC2-Ubuntu" {
  depends_on = [ module.service_network,module.service_network ]
  ami           = "ami-0e86e20dae9224db8" 
  instance_type = "t2.micro"
  key_name      = var.keyname
  
  # user_data = data.template_file.apache_install.rendered
  network_interface {
    network_interface_id = aws_network_interface.ftd_app.id
    device_index         = 0
  }

  tags = {
    Name = "${var.prefix}-Inside-Machine"
  }
}
