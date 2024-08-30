resource "aws_subnet" "bastion_subnet" {
  vpc_id                  = aws_vpc.ftd_vpc[0].id
  cidr_block              = "172.16.8.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-bastion-Subnet"})
}

resource "aws_network_interface" "bastion_interface" {
  description = "bastion-interface"
  subnet_id   = aws_subnet.bastion_subnet.id
  private_ips = ["172.16.8.30"]
}

resource "aws_network_interface_sg_attachment" "bastion_attachment" {
  depends_on           = [aws_network_interface.bastion_interface]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.bastion_interface.id
}

resource "aws_route_table" "bastion_route" {
  vpc_id = aws_vpc.ftd_vpc.id
  tags = {
    Name = "${var.prefix}-bastion network Routing table"}
}

resource "aws_route_table_association" "bastion_association" {
  subnet_id      = aws_subnet.bastion_subnet.id
  route_table_id = aws_route_table.bastion_route.id
}

resource "aws_route" "bastion_default_route" {
  route_table_id         = aws_route_table.bastion_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.int_gw.id
}

resource "aws_instance" "testLinux" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "${var.prefix}-${var.keyname}"
  network_interface {
    network_interface_id = aws_network_interface.bastion_interface.id
    device_index         = 0
  }

  tags = {
    Name = "${var.prefix}-bastion"
  }
}