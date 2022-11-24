#------------------------------------------------
#------------------------------------------------
# ------ Web Server from Roman Peklov -----------
#------------------------------------------------
#------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# TODO Убрать хардкод в переменные

#------------------------------------------------
# -----------      Data block
#------------------------------------------------

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux_latest" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name      = "name"
    values    = ["amzn2-ami-kernel-*"]
  }
}

data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_route_table" "current" {
  vpc_id = aws_vpc.vpc_for_web.id
  depends_on = [aws_vpc.vpc_for_web]
}
#-------------------------------------------------
# ---------     Recourses block
#-------------------------------------------------

# TODO IAM roles, S3 bucket, RDS db instance

# VPC creation
resource "aws_vpc" "vpc_for_web" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-for-WebServer"
  }
}

# Internet GW creation
resource "aws_internet_gateway" "egw_for_webserver" {
  vpc_id = aws_vpc.vpc_for_web.id
}

# Private subnet creation
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc_for_web.id
  tags = {
    Name = "Private-subnet-for-WebServer"
  }
}

# Default route table creation
resource "aws_default_route_table" "public_route_table" {
   default_route_table_id = data.aws_route_table.current.id
  depends_on = [aws_vpc.vpc_for_web]
}

# Security group creation
resource "aws_security_group" "for_ec2" {
  name                         = "for_ec2"
  description                  = "Test SG SSH and HTTP/HTTPS"
  vpc_id                       = aws_vpc.vpc_for_web.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description                = "HTTP/HTTPS access"
      from_port                  = ingress.value
      to_port                    = ingress.value
      protocol                   = "tcp"
      cidr_blocks                = ["0.0.0.0/0"]
    }
  }

  ingress {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Instance configuration
resource "aws_instance" "webserver" {
  ami                         = data.aws_ami.amazon_linux_latest.id
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.for_ec2.id]
  subnet_id                   = aws_subnet.private_subnet.id
  key_name                    = "key1"
  associate_public_ip_address = true
  iam_instance_profile        = "test-s3-acc"

   lifecycle {
    ignore_changes = [security_groups]
 }
}

#Elastic load balancer creation
resource "aws_elb" "elb_for_webserver" {
  name               = "WebServer-elb"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    #ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName" #TODO Прикрутить SSL
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 10
  }
  depends_on = [aws_default_subnet.subnet_az1, aws_default_subnet.subnet_az2]
}

resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available.names[0] #TODO  Error: error creating EC2 Subnet: MissingParameter: Either 'cidrBlock' or 'ipv6CidrBlock' should be provided.
}

resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available.names[1] #TODO  Error: error creating EC2 Default Subnet (us-east-1a): DefaultVpcDoesNotExist: No default VPC exists for this account in this region.
}

output "instance_public_ip" {
  value = aws_instance.webserver.public_ip
}