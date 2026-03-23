variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "deployment_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "mrc"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "jlp"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for instances"
  type        = string
  default     = "ubuntu"
}

variable "broker_instance_type" {
  description = "Machine type for Redpanda broker instances"
  type        = string
  default     = "n2-standard-4"
}

variable "client_instance_type" {
  description = "Machine type for client instances"
  type        = string
  default     = "e2-medium"
}

variable "monitor_instance_type" {
  description = "Machine type for monitoring instance"
  type        = string
  default     = "e2-medium"
}

variable "brokers_per_region" {
  description = "Number of Redpanda brokers per region"
  type        = number
  default     = 2
}

variable "redpanda_version" {
  description = "Redpanda version to deploy"
  type        = string
  default     = "25.3.9-1"
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "redpanda_license" {
  description = "Redpanda enterprise license key"
  type        = string
  sensitive   = true
  default     = ""
}

locals {
  regions = {
    us = {
      region     = "us-east4"
      zone       = "us-east4-a"
      vpc_cidr   = "10.0.0.0/16"
      subnet_cidr = "10.0.1.0/24"
    }
    eu = {
      region     = "europe-west1"
      zone       = "europe-west1-b"
      vpc_cidr   = "10.1.0.0/16"
      subnet_cidr = "10.1.1.0/24"
    }
    kr = {
      region     = "asia-northeast3"
      zone       = "asia-northeast3-a"
      vpc_cidr   = "10.2.0.0/16"
      subnet_cidr = "10.2.1.0/24"
    }
  }

  common_labels = {
    owner       = var.owner
    project     = var.deployment_prefix
    environment = "demo"
    managed_by  = "terraform"
  }
}
