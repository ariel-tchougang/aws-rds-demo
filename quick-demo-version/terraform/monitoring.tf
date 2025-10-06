# Mission DB007 - CloudWatch Monitoring Configuration
# Monitoring and alerting for Multi-AZ RDS demonstration

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "application" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-log-group"
  })
}

# IAM Role for CloudWatch Metrics and Logs
resource "aws_iam_role" "cloudwatch" {
  name_prefix = "${var.project_name}-cloudwatch-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })



  tags = local.common_tags
}

# IAM Policy for Custom Metrics
resource "aws_iam_role_policy" "custom_metrics" {
  name_prefix = "${var.project_name}-custom-metrics-"
  role        = aws_iam_role.cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = var.metric_namespace
          }
        }
      }
    ]
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "cloudwatch" {
  name_prefix = "${var.project_name}-cloudwatch-"
  role        = aws_iam_role.cloudwatch.name

  tags = local.common_tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "mission" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.identifier],
            [".", "CPUUtilization", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Performance Metrics"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [var.metric_namespace, "DatabaseResponseTime", "Operation", "SELECT"],
            [".", ".", ".", "INSERT"],
            [".", "DatabaseConnectionStatus", "Status", "Connected"],
            [".", ".", ".", "Disconnected"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Metrics"
          period  = 60
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            [var.metric_namespace, "FailoverDuration", "Event", "Failover"],
            [".", "RecoveryTime", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Failover Metrics"
          period  = 60
          stat    = "Maximum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '${var.log_group_name}'\n| fields @timestamp, level, message, operation\n| filter level = \"ERROR\" or level = \"WARN\" or message like /failover/i\n| sort @timestamp desc\n| limit 100"
          region = var.aws_region
          title  = "Critical Events and Failover Logs"
          view   = "table"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "database_connection" {
  alarm_name          = "${var.project_name}-database-connection-failure"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnectionStatus"
  namespace           = var.metric_namespace
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Alert when database connection fails"
  treat_missing_data  = "breaching"

  dimensions = {
    Status = "Connected"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseResponseTime"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "Alert when database response time is high"
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when RDS CPU utilization is high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = local.common_tags
}

# IAM Policy Attachment for CloudWatch role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-alerts"
  display_name = "DB007 Mission Alerts"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alerts-topic"
  })
}