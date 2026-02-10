data "terraform_remote_state" "dev" {
  backend = "s3"

  config = {
    bucket = "codoc-terraform-state"
    key    = "codoc/dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "app" {
  source = "../../modules/app"

  project_name      = var.project_name
  instance_type     = var.instance_type
  root_volume_gb    = var.root_volume_gb
  key_name          = var.key_name
  ssh_cidr          = var.ssh_cidr
  availability_zone = var.availability_zone
  ami_id            = var.ami_id
  ami_name          = var.ami_name
  ami_owners        = var.ami_owners
  eic_sg_id         = data.terraform_remote_state.dev.outputs.eic_sg_id
  use_existing_vpc  = true
  existing_vpc_id   = data.terraform_remote_state.dev.outputs.vpc_id
  existing_subnet_id = data.terraform_remote_state.dev.outputs.subnet_id
  create_eic_endpoint = false
  eic_ingress_cidr     = var.eic_ingress_cidr
  enable_log_insights  = var.enable_log_insights
  spring_log_group_names = var.spring_log_group_names
  nginx_log_group_names  = var.nginx_log_group_names
}

data "aws_route53_zone" "codoc" {
  name         = "codoc.cloud"
  private_zone = false
}

resource "aws_route53_record" "root_a" {
  zone_id = data.aws_route53_zone.codoc.zone_id
  name    = "codoc.cloud"
  type    = "A"
  ttl     = 300
  records = [module.app.eip_public_ip]
}

resource "aws_route53_record" "dev_a" {
  zone_id = data.aws_route53_zone.codoc.zone_id
  name    = "dev.codoc.cloud"
  type    = "A"
  ttl     = 300
  records = [data.terraform_remote_state.dev.outputs.eip_public_ip]
}
