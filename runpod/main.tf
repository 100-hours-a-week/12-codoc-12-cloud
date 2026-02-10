terraform {
  required_version = ">= 1.6.0"

  required_providers {
    runpod = {
      source  = "runpod/runpod"
      version = "~> 1.0"
    }
  }
}

provider "runpod" {
  api_key = var.runpod_api_key
}

variable "runpod_api_key" {}
variable "gpu_type" {
  default = "NVIDIA_L4"
}

variable "allowed_ingress_cidr" {
  description = "Allowed source IP (logical, documented only)"
  type        = string
}

resource "runpod_pod" "gpu_pod" {
  name         = "gpu-inference"
  gpu_type     = var.gpu_type
  gpu_count    = 1
  cloud_type   = "SECURE"
  volume_size  = 50
  container_disk_in_gb = 50

  image_name = "ubuntu:22.04"

  ports = [
    {
      container_port = 80
      public_port    = 80
      protocol       = "tcp"
    },
    {
      container_port = 443
      public_port    = 443
      protocol       = "tcp"
    }
  ]

  env = {
    ALLOWED_SOURCE = var.allowed_ingress_cidr
  }
}

output "endpoint" {
  value = runpod_pod.gpu_pod.endpoint
}
