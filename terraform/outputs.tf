output "vpc_id" {
  value = aws_vpc.vpc_for_web.id
}

output "instance_ips" {
  value = aws_instance.webserver[*].private_ip
}

output "lb_dns" {
  value = aws_lb.webserver-elb.dns_name
}

output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "nat_eip" {
  value = aws_eip.elastic_ip.association_id
}

output "instanse_id" {
  value = aws_instance.webserver[*].id
}

output "db_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}