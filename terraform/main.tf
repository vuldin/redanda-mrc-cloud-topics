terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Provider aliases for each region ---

provider "aws" {
  alias  = "us"
  region = "us-east-1"

  default_tags {
    tags = {
      Project    = "mrc-cloud-topics"
      Owner      = var.owner
      Prefix     = var.deployment_prefix
      ManagedBy  = "terraform"
    }
  }
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"

  default_tags {
    tags = {
      Project    = "mrc-cloud-topics"
      Owner      = var.owner
      Prefix     = var.deployment_prefix
      ManagedBy  = "terraform"
    }
  }
}

provider "aws" {
  alias  = "ap"
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project    = "mrc-cloud-topics"
      Owner      = var.owner
      Prefix     = var.deployment_prefix
      ManagedBy  = "terraform"
    }
  }
}
