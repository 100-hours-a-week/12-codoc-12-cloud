output "ec2_public_ip" {
  value = module.app.ec2_public_ip
}

output "ec2_public_dns" {
  value = module.app.ec2_public_dns
}

output "eip_public_ip" {
  value = module.app.eip_public_ip
}

output "vpc_id" {
  value = module.app.vpc_id
}

output "subnet_id" {
  value = module.app.subnet_id
}

output "eic_sg_id" {
  value = module.app.eic_sg_id
}

output "eic_endpoint_id" {
  value = module.app.eic_endpoint_id
}
