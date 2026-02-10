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
  instance_profile_name = var.instance_profile_name
  eic_sg_id         = var.eic_sg_id
  use_existing_vpc  = var.use_existing_vpc
  existing_vpc_id   = var.existing_vpc_id
  existing_subnet_id = var.existing_subnet_id
  create_eic_endpoint = var.create_eic_endpoint
  eic_ingress_cidr     = var.eic_ingress_cidr
  enable_log_insights  = var.enable_log_insights
  spring_log_group_names = var.spring_log_group_names
  nginx_log_group_names  = var.nginx_log_group_names
}
