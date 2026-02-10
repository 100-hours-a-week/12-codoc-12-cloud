terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" {}
variable "region" { default = "asia-northeast3" }
variable "zone"   { default = "asia-northeast3-a" }

variable "allowed_ingress_cidr" {
  description = "AWS EIP or trusted CIDR"
  type        = string
}

variable "machine_type" {
  default = "n1-standard-4"
}

variable "gpu_type" {
  default = "nvidia-l4"
}

variable "gpu_count" {
  default = 1
}

resource "google_compute_network" "this" {
  name                    = "gpu-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = "gpu-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_firewall" "http_https" {
  name    = "allow-http-https"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [var.allowed_ingress_cidr]
  target_tags   = ["gpu-app"]
}

resource "google_compute_instance" "gpu_vm" {
  name         = "gpu-instance"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["gpu-app"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    access_config {}
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  metadata = {
    enable-oslogin = "FALSE"
  }
}

output "public_ip" {
  value = google_compute_instance.gpu_vm.network_interface[0].access_config[0].nat_ip
}
