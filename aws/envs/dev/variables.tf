variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "codoc-dev"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "root_volume_gb" {
  type    = number
  default = 15
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "availability_zone" {
  type    = string
  default = "ap-northeast-2a"
}

variable "ami_id" {
  type        = string
  description = "Custom AMI ID for dev environment"
}

variable "ami_name" {
  type        = string
  default     = ""
  description = "AMI name for dev environment"
}

variable "ami_owners" {
  type        = list(string)
  default     = ["self"]
  description = "AMI owners for dev environment"
}

variable "instance_profile_name" {
  type        = string
  default     = ""
  description = "IAM instance profile name for dev environment"
}

variable "eic_sg_id" {
  type        = string
  default     = ""
  description = "EIC Endpoint security group ID"
}

variable "use_existing_vpc" {
  type        = bool
  default     = false
  description = "Use existing VPC/Subnet instead of creating new ones"
}

variable "existing_vpc_id" {
  type        = string
  default     = ""
  description = "Existing VPC ID to use when use_existing_vpc is true"
}

variable "existing_subnet_id" {
  type        = string
  default     = ""
  description = "Existing Subnet ID to use when use_existing_vpc is true"
}

variable "create_eic_endpoint" {
  type        = bool
  default     = false
  description = "Create an EC2 Instance Connect Endpoint in the VPC"
}

variable "eic_ingress_cidr" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed to reach the EIC endpoint"
}

variable "enable_log_insights" {
  type        = bool
  default     = true
  description = "Enable CloudWatch Logs Insights saved queries and dashboard."
}

variable "spring_log_group_names" {
  type        = list(string)
  default     = []
  description = "CloudWatch Log Group names for Spring backend logs."
}

variable "nginx_log_group_names" {
  type        = list(string)
  default     = []
  description = "CloudWatch Log Group names for Nginx access logs."
}
