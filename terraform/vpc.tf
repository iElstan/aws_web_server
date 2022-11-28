#------------------------------------------------
# --------------- VPC Module --------------------
#------------------------------------------------

# VPC creation
resource "aws_vpc" "vpc_for_web" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "VPC-for-WebServer"
  }
}

# Internet GW creation
resource "aws_internet_gateway" "igw_for_webserver" {
  vpc_id = aws_vpc.vpc_for_web.id
  tags = {
    Name = "IGW-for-WebServer"
  }
}

# Public subnet creation
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.vpc_for_web.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${count.index + 1}-public-subnet-for-WebServer"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_for_web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_for_webserver.id
  }
  tags = {
    Name = "Route-table-for-public-subnets"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count = length(aws_subnet.public_subnets[*].id)
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway creation
resource "aws_eip" "elastic_ip" {
  count = length(var.private_subnet_cidrs)
  vpc = true
  tags = {
    Name = "Elastic-IP-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = length(var.private_subnet_cidrs)
  allocation_id = element(aws_eip.elastic_ip[*].id, count.index)
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)
  depends_on = [aws_internet_gateway.igw_for_webserver]
  tags = {
    Name = "NAT-GW-${count.index + 1}"
  }
}

# Private subnet creation
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.vpc_for_web.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${count.index + 1}-private-subnet-for-WebServer"
  }
}

# Private route table creation
resource "aws_route_table" "private_route_table" {
  count = length(aws_subnet.private_subnets)
  vpc_id = aws_vpc.vpc_for_web.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  tags = {
    Name = "${count.index + 1}-Route-table-for-private-subnets"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(aws_route_table.private_route_table)
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index )
  route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
}