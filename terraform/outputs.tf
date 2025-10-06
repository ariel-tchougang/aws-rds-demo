# Mission DB007 - Terraform Outputs
# Output values for Mission DB007 infrastructure

# VPC Outputs
output "vpc_id" {
  description = "VPC ID for Mission DB007"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Security Group Outputs
output "application_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database.id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# Availability Zone Outputs
output "availability_zones" {
  description = "Availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "primary_availability_zone" {
  description = "Primary availability zone"
  value       = data.aws_availability_zones.available.names[0]
}

output "secondary_availability_zone" {
  description = "Secondary availability zone"
  value       = data.aws_availability_zones.available.names[1]
}

# CloudWatch Outputs
output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.dashboard_name}"
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "cloudwatch_role_arn" {
  description = "CloudWatch IAM Role ARN"
  value       = aws_iam_role.cloudwatch.arn
}

output "instance_profile_arn" {
  description = "Instance Profile ARN for EC2"
  value       = aws_iam_instance_profile.cloudwatch.arn
}

output "metric_namespace" {
  description = "Custom metrics namespace"
  value       = var.metric_namespace
}

output "alerts_topic_arn" {
  description = "SNS Topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

# Mission Summary
# VPC CIDR Output
output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

# Workspace IAM Outputs
output "workspace_role_arn" {
  description = "IAM Role ARN for EC2/Cloud9 instances"
  value       = aws_iam_role.workspace.arn
}

output "workspace_instance_profile_arn" {
  description = "Instance Profile ARN for EC2 instances"
  value       = aws_iam_instance_profile.workspace.arn
}

output "workspace_instance_profile_name" {
  description = "Instance Profile name for EC2 instances"
  value       = aws_iam_instance_profile.workspace.name
}

output "mission_summary" {
  description = "Mission DB007 deployment summary"
  value = {
    project_name    = var.project_name
    vpc_id         = aws_vpc.main.id
    vpc_cidr       = aws_vpc.main.cidr_block
    rds_endpoint   = aws_db_instance.main.endpoint
    primary_az     = data.aws_availability_zones.available.names[0]
    secondary_az   = data.aws_availability_zones.available.names[1]
    dashboard_url  = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.dashboard_name}"
    multi_az       = aws_db_instance.main.multi_az
  }
}