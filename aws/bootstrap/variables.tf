variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
}
