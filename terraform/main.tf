#------------------------------------------------
#------------------------------------------------
# ------ Web Server by Roman Peklov -----------
#------------------------------------------------
#------------------------------------------------

#------------------------------------------------
# -----------      Data block
#------------------------------------------------

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_ami" "amazon_linux_latest" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name      = "name"
    values    = ["amzn2-ami-kernel-*"]
  }
}

#-------------------------------------------------
# ---------     Recourses block
#-------------------------------------------------

# EC2 Instance configuration
resource "aws_instance" "webserver" {
  count                       = var.instances_count
  ami                         = data.aws_ami.amazon_linux_latest.id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.for_ec2.id]
  subnet_id                   = aws_subnet.private_subnets[count.index].id
  key_name                    = var.key_pair_name
  availability_zone           = data.aws_availability_zones.available.names[count.index]
  associate_public_ip_address = false
//  iam_instance_profile        = aws_iam_role.s3_for_ec2.name #TODO IAM for S3
  user_data                   = "${file("userdata.sh")}"

   lifecycle {
    ignore_changes = [security_groups]
 }
  tags = {
    Name = "EC2-Webserver-${count.index + 1}"
  }
}

#RDS Instance creation # TODO RDS db instance
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  db_name              = "webdb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "vasya"
  password             = "vasiliy1"
  skip_final_snapshot  = true
}

# Security group for EC2 creation
resource "aws_security_group" "for_ec2" {
  name                         = "for_ec2"
  description                  = "HTTP access to LB"
  vpc_id                       = aws_vpc.vpc_for_web.id
  ingress {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc_for_web.cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Security group for Load balancer creation
resource "aws_security_group" "for_lb" {
  name                         = "for_lb"
  description                  = "SH and HTTP/HTTPS"
  vpc_id                       = aws_vpc.vpc_for_web.id

  dynamic "ingress" {
    for_each = var.sg_ingress_ports[*]
    content {
      description                = "HTTP/HTTPS access"
      from_port                  = ingress.value
      to_port                    = ingress.value
      protocol                   = "tcp"
      cidr_blocks                = ["0.0.0.0/0"]
    }
  }
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#Elastic load balancer creation
resource "aws_lb" "webserver-elb" {
  load_balancer_type = "application"
  subnets = [for subnet in aws_subnet.public_subnets : subnet.id]
  security_groups = [aws_security_group.for_lb.id]
  internal = false
  tags = {
    Name = "EC2-Webserver-Load-Balancer"
  }
}

resource "aws_lb_listener" "port_80" {
  load_balancer_arn = aws_lb.webserver-elb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver_tg.arn
  }
}

resource "aws_lb_target_group" "webserver_tg" {
  name     = "Webserver-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_for_web.id
}
