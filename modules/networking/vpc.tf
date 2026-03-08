# VPC module

resource "aws_vpc" "this" {
  cidr_block = var.vpc_config.cidr_block

  tags = {
    Name = var.vpc_config.name
  }

}

# Subnet model
resource "aws_subnet" "this" {
  for_each                = var.subnet_config
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = each.key
  }
}

#create list of private and public subnet, create variable aws_subnet.this[name].id identify first public subnet
locals {
  public_subnets = {
    for name, subnet in var.subnet_config : name => subnet
    if subnet.public
  }

  private_subnets = {
    for name, subnet in var.subnet_config : name => subnet
    if !subnet.public
  }

  public_subnet_ids = [
    for name in sort(keys(local.public_subnets)) :
    aws_subnet.this[name].id
  ]
}
#IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "IGW public subnet"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.vpc_config.name}-public-rtb"
  }
}

# Associate all public subnets with public route table
resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for name, subnet in var.subnet_config : name => subnet
    if subnet.public
  }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public_rtb.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_config.name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway in a public subnet
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.public_subnet_ids[0]

  tags = {
    Name = "${var.vpc_config.name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private route table
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.vpc_config.name}-private-rtb"
  }
}

# Associate all private subnets with private route table
resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for name, subnet in var.subnet_config : name => subnet
    if !subnet.public
  }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_rtb.id
}