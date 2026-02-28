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

variable "ssh_key_name" {
  description = "Name of the AWS key pair (if pre-existing)"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for creating a key pair"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  description = "SSH user for EC2 instances (ubuntu for Ubuntu AMI)"
  type        = string
  default     = "ubuntu"
}

variable "broker_instance_type" {
  description = "EC2 instance type for Redpanda brokers"
  type        = string
  default     = "i3.large"
}

variable "client_instance_type" {
  description = "EC2 instance type for workload generators"
  type        = string
  default     = "t3.medium"
}

variable "monitor_instance_type" {
  description = "EC2 instance type for monitoring"
  type        = string
  default     = "t3.medium"
}

variable "brokers_per_region" {
  description = "Number of Redpanda brokers per region"
  type        = number
  default     = 2
}

variable "redpanda_version" {
  description = "Redpanda version to install"
  type        = string
  default     = "25.3.9-1"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "redpanda_license" {
  description = "Redpanda enterprise license key"
  type        = string
  default     = ""
  sensitive   = true
}

# Region configuration
locals {
  regions = {
    us = {
      region     = "us-east-1"
      vpc_cidr   = "10.0.0.0/16"
      subnet_cidr = "10.0.1.0/24"
      az         = "us-east-1a"
    }
    eu = {
      region     = "eu-west-1"
      vpc_cidr   = "10.1.0.0/16"
      subnet_cidr = "10.1.1.0/24"
      az         = "eu-west-1a"
    }
    ap = {
      region     = "ap-southeast-1"
      vpc_cidr   = "10.2.0.0/16"
      subnet_cidr = "10.2.1.0/24"
      az         = "ap-southeast-1a"
    }
  }

  all_vpc_cidrs = [for r in local.regions : r.vpc_cidr]
}
