output "vpc_id" {
  value = aws_vpc.vpc_for_web.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "instance_ids" {
  value = aws_instance.webserver[*].id
}

output "lb_arn" {
  value = aws_lb.webserver-elb.arn
}