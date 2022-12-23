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


variable "lb_sg_ports" {
  default = ["80", "443"]
}

variable "ec2_sg_ports" {
  default = ["80", "22", "3306"]
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

variable "iam_policy_s3_RO" {
  default = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

variable "iam_policy_ecr" {
  default = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

variable "ssl_cert_arn" {
  default = "arn:aws:acm:us-east-1:294360715377:certificate/e4ec7a08-3a4d-4d26-b5a0-db9c9cd40605"
}

variable "db_name" {
  default = "webdb"
}

variable "db_username" {
  description = "DB user name"
  sensitive = true
}

variable "db_password" {
  description = "DB password"
  sensitive = true
}

variable "db_instance_type" {
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  default = 10
}

variable "db_engine" {
  default = "mysql"
}

variable "db_engine_version" {
  default = "8.0"
}

variable "s3name" {
  default = "rpeklov-webserver-data"
}

variable "config_link" {
  default = "../config"
}