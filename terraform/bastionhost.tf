data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

# Bastion host instance configuration
resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.amazon_linux_latest.id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.for_bastion.id]
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.key_pair_name
  availability_zone           = data.aws_availability_zones.available.names[0]
  iam_instance_profile        = aws_iam_instance_profile.webserver.name
  associate_public_ip_address = true
  user_data                   = file("bastiondata.sh")
  depends_on                  = [aws_s3_object.settings]

  lifecycle {
    ignore_changes = [security_groups]
 }
  tags = {
    Name = "Bastion host"
  }
}

# Bastion host security group
resource "aws_security_group" "for_bastion" {
  name               = "for_bastion"
  description        = "SSH access"
  vpc_id             = aws_vpc.vpc_for_web.id
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
