# Mission DB007 - RDS Configuration
# Multi-AZ PostgreSQL database for resilience demonstration

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix = "${var.project_name}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })



  tags = local.common_tags
}

# IAM Policy Attachment for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance (Multi-AZ PostgreSQL)
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Engine Configuration
  engine         = "postgres"
  engine_version = "15.14"
  instance_class = var.db_instance_class

  # Storage Configuration
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  # Multi-AZ Configuration
  multi_az = true

  # Backup Configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Monitoring Configuration
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Deletion Configuration
  deletion_protection       = false
  delete_automated_backups = true
  skip_final_snapshot      = true

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-postgres"
    Purpose = "Multi-AZ Demonstration"
  })
}