# Mission DB007 - Terraform Variables
# Variable definitions for DataCorp resilience demonstration

# AWS Configuration
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "db007-mission"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium",
      "db.t3.large", "db.m5.large", "db.m5.xlarge"
    ], var.db_instance_class)
    error_message = "DB instance class must be a valid RDS instance type."
  }
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "datacorp"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "db007"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# CloudWatch Monitoring Configuration
variable "dashboard_name" {
  description = "CloudWatch Dashboard name"
  type        = string
  default     = "DB007-Mission-Dashboard"
}

variable "metric_namespace" {
  description = "Custom metrics namespace"
  type        = string
  default     = "DB007/Mission"
}

variable "log_group_name" {
  description = "CloudWatch Log Group name"
  type        = string
  default     = "/aws/db007/application"
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# Application Configuration
variable "app_monitoring_interval" {
  description = "Application monitoring interval in seconds"
  type        = number
  default     = 5
}

variable "app_traffic_rate" {
  description = "Application traffic generation rate per second"
  type        = number
  default     = 10
}

variable "failover_timeout" {
  description = "Failover timeout in seconds"
  type        = number
  default     = 300
}

# Network Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrnetmask(var.vpc_cidr)) && tonumber(regex("\\/(\\d+)$", var.vpc_cidr)[0]) >= 16 && tonumber(regex("\\/(\\d+)$", var.vpc_cidr)[0]) <= 28
    error_message = "VPC CIDR must be a valid IPv4 CIDR block with prefix length between /16 and /28."
  }
}

variable "client_access_cidr" {
  description = "CIDR block for database access (SECURITY: Use your IP/32 for better security, or 0.0.0.0/0 for CloudShell)"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition = can(cidrhost(var.client_access_cidr, 0))
    error_message = "Client access CIDR must be a valid CIDR block (e.g., 203.0.113.42/32)."
  }
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Mission     = "DB007"
    Purpose     = "Multi-AZ-Demonstration"
    Environment = "Demo"
    Owner       = "DataCorp"
  }
}