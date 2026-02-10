terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "codoc-terraform-state"
    key    = "codoc/dev/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
