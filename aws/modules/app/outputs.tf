output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.app.public_dns
}

output "eip_public_ip" {
  value = aws_eip.app.public_ip
}

output "vpc_id" {
  value = local.vpc_id
}

output "subnet_id" {
  value = local.subnet_id
}

output "eic_sg_id" {
  value = local.eic_sg_id
}

output "eic_endpoint_id" {
  value = try(aws_ec2_instance_connect_endpoint.this[0].id, null)
}
