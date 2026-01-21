variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

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
  description = "EC2 Key Pair name (NOT the .pem filename)"
}

variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0" # 지금은 전체 허용. 나중에 내 IP로 바꾸자.
}