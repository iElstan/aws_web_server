variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "sg_ingress_ports" {
  default = ["80", "443"]
}

variable "key_pair_name" {
  default = "key1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instances_count" {
  default = 2
}