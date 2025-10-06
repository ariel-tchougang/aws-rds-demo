# Mission DB007 - Main Terraform Configuration
# Agent DB007 infrastructure deployment for DataCorp

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      ManagedBy   = "Terraform"
    })
  }
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  common_tags = merge(var.tags, {
    Name = var.project_name
  })
}