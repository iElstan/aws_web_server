#------------------------------------------------
#------------------------------------------------
# ------ Web Server by Roman Peklov -----------
#------------------------------------------------
#------------------------------------------------

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "aws_ami" "amazon_linux_latest" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name      = "name"
    values    = ["amzn2-ami-kernel-*"]
  }
}

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
  iam_instance_profile        = aws_iam_instance_profile.webserver.name
  user_data                   = file("userdata.sh")
  tags = {
    Name = "EC2-Webserver-${count.index + 1}"
  }
  lifecycle {
    ignore_changes = [security_groups]
 }
}

#RDS Instance creation
resource "aws_db_instance" "db_instance" {
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_type
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.for_ec2.id]
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "rds" {
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
}

# Security group for EC2 creation
resource "aws_security_group" "for_ec2" {
  name               = "for_ec2"
  description        = "HTTP access to instances"
  vpc_id             = aws_vpc.vpc_for_web.id

  dynamic "ingress" {
    for_each = var.ec2_sg_ports
    content {
    description      = "HTTP, SSH, MySQL access"
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc_for_web.cidr_block]
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

# Security group for Load balancer creation
resource "aws_security_group" "for_lb" {
  name         = "for_lb"
  description  = "HTTP/HTTPS access to LB"
  vpc_id       = aws_vpc.vpc_for_web.id

  dynamic "ingress" {
    for_each = var.lb_sg_ports[*]
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
  name = "EC2-Webserver-LB"
  load_balancer_type  = "application"
  subnets             = [for subnet in aws_subnet.public_subnets : subnet.id]
  security_groups     = [aws_security_group.for_lb.id]
  internal            = false
}

resource "aws_lb_listener" "port_443" {
  load_balancer_arn = aws_lb.webserver-elb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_cert_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webserver_tg.arn
  }
}

resource "aws_lb_listener" "port_80" {
  load_balancer_arn = aws_lb.webserver-elb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "webserver_tg" {
  name     = "Webserver-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_for_web.id
  depends_on = [aws_lb.webserver-elb, aws_instance.webserver]
}

resource "aws_lb_target_group_attachment" "webserver_tg" {
  count            = length(aws_instance.webserver)
  target_group_arn = aws_lb_target_group.webserver_tg.arn
  target_id        = element(aws_instance.webserver[*].id, count.index)
  port             = 80
}
