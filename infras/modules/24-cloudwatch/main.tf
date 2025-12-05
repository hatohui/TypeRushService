# ========================================
# CloudWatch Monitoring and Alarms
# ========================================

data "aws_region" "current" {}

# ========================================
# ECS Service Alarms
# ========================================

# ECS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  count               = var.enable_ecs_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilization above 80%"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.tags
}

# ECS High Memory Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  count               = var.enable_ecs_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS memory utilization above 80%"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.tags
}

# ECS Service Unhealthy Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_service_unhealthy" {
  count               = var.enable_ecs_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-service-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ECS service has no running tasks"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.tags
}

# ========================================
# Lambda Function Alarms
# ========================================

# Record Service Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "record_lambda_errors" {
  count               = var.enable_lambda_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-record-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Record Service Lambda errors exceeded 10 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    FunctionName = var.record_lambda_name
  }

  tags = var.tags
}

# Record Service Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "record_lambda_duration" {
  count               = var.enable_lambda_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-record-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 25000 # 25 seconds, near 30s timeout
  alarm_description   = "Record Service Lambda duration approaching timeout"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = var.record_lambda_name
  }

  tags = var.tags
}

# Text Service Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "text_lambda_errors" {
  count               = var.enable_lambda_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-text-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Text Service Lambda errors exceeded 10 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    FunctionName = var.text_lambda_name
  }

  tags = var.tags
}

# ========================================
# RDS Alarms
# ========================================

# RDS Low Free Storage
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count               = var.enable_rds_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2GB in bytes
  alarm_description   = "RDS free storage space below 2GB"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

# RDS High CPU
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  count               = var.enable_rds_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization above 80% for 10 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

# RDS High Database Connections
resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  count               = var.enable_rds_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 40 # 80% of t3.micro max connections (~50)
  alarm_description   = "RDS database connections above 80% of maximum"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

# ========================================
# ElastiCache Alarms
# ========================================

# ElastiCache High CPU
resource "aws_cloudwatch_metric_alarm" "elasticache_high_cpu" {
  count               = var.enable_elasticache_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-elasticache-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "ElastiCache CPU above 75%"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    CacheClusterId = var.elasticache_cluster_id
  }

  tags = var.tags
}

# ElastiCache High Memory Usage
resource "aws_cloudwatch_metric_alarm" "elasticache_high_memory" {
  count               = var.enable_elasticache_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-elasticache-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "ElastiCache memory usage above 90%"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    CacheClusterId = var.elasticache_cluster_id
  }

  tags = var.tags
}

# ElastiCache High Evictions
resource "aws_cloudwatch_metric_alarm" "elasticache_high_evictions" {
  count               = var.enable_elasticache_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-elasticache-high-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "ElastiCache evictions exceeded 1000 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    CacheClusterId = var.elasticache_cluster_id
  }

  tags = var.tags
}

# ========================================
# API Gateway Alarms
# ========================================

# API Gateway High 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  count               = var.enable_api_gateway_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5XX errors exceeded 10 in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}

# API Gateway High Latency
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count               = var.enable_api_gateway_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # 2 seconds
  alarm_description   = "API Gateway p99 latency above 2 seconds"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}

# ========================================
# CloudWatch Dashboard
# ========================================

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", label = "ECS CPU" }],
            [".", "MemoryUtilization", { stat = "Average", label = "ECS Memory" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "ECS Service Metrics"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Throttles", { stat = "Sum", label = "Throttles" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.id
          title  = "Lambda Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "RDS CPU" }],
            [".", "DatabaseConnections", { stat = "Average", label = "Connections" }],
            [".", "FreeStorageSpace", { stat = "Average", label = "Free Storage" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "RDS Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", { stat = "Average", label = "Redis CPU" }],
            [".", "DatabaseMemoryUsagePercentage", { stat = "Average", label = "Memory Usage" }],
            [".", "CurrConnections", { stat = "Average", label = "Connections" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "ElastiCache Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Requests" }],
            [".", "4XXError", { stat = "Sum", label = "4XX Errors" }],
            [".", "5XXError", { stat = "Sum", label = "5XX Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.id
          title  = "API Gateway Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", { stat = "Average", label = "Avg Latency" }],
            ["...", { stat = "p99", label = "p99 Latency" }]
          ]
          period = 300
          region = data.aws_region.current.id
          title  = "API Gateway Latency"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}
