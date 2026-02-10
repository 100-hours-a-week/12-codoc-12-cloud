variable "project_name" {
  type    = string
  default = "codoc"
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
  description = "Custom AMI ID for the instance"
}

variable "ami_name" {
  type        = string
  default     = ""
  description = "AMI name to lookup when ami_id is not provided"
  validation {
    condition     = var.ami_id != "" || var.ami_name != ""
    error_message = "When ami_id is empty, ami_name must be provided."
  }
}

variable "ami_owners" {
  type        = list(string)
  default     = ["self"]
  description = "AMI owners for lookup (default: self)"
}

variable "instance_profile_name" {
  type        = string
  default     = ""
  description = "Existing IAM Instance Profile name to attach to EC2"
}

variable "eic_sg_id" {
  type        = string
  default     = ""
  description = "Security group ID for EC2 Instance Connect Endpoint"
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
