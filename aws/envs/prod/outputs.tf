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
