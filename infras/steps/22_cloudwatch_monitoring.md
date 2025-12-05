# Step 22: CloudWatch Monitoring and Alarms

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/21-cloudwatch`

## Overview

Configure Amazon CloudWatch for centralized logging, metrics, and alarms to monitor infrastructure health and application performance.

## Architecture Reference

From `architecture-diagram.md`:

- **Log Groups**: ECS, Lambda, API Gateway, WAF
- **Metrics**: ECS CPU/Memory, Lambda errors, API Gateway latency
- **Alarms**: SNS notifications for critical issues
- **Retention**: 7 days (dev cost optimization)
- **Cost**: ~$3/month (minimal logs + alarms)

## Components to Implement

### 1. Log Groups

- [ ] `/ecs/typerush-dev-game-service` (7-day retention)
- [ ] `/aws/lambda/typerush-dev-record-service` (7-day retention)
- [ ] `/aws/lambda/typerush-dev-text-service` (7-day retention)
- [ ] `/aws/apigateway/typerush-dev-http-api` (optional)
- [ ] `/aws/apigateway/typerush-dev-ws-api` (optional)
- [ ] `/aws/waf/typerush-dev` (7-day retention)

### 2. Metric Alarms

#### ECS Service Alarms

- [ ] **High CPU**: CPU > 80% for 2 consecutive periods
- [ ] **High Memory**: Memory > 80% for 2 consecutive periods
- [ ] **Service Unhealthy**: Running task count < 1 for 1 minute

#### Lambda Alarms

- [ ] **High Error Rate**: Errors > 10 in 5 minutes
- [ ] **High Duration**: Duration > 25 seconds (near timeout)
- [ ] **Throttles**: Throttled invocations > 0

#### API Gateway Alarms

- [ ] **High 5XX Errors**: Count > 10 in 5 minutes
- [ ] **High Latency**: p99 latency > 2 seconds

#### RDS Alarms

- [ ] **Low Free Storage**: < 2GB remaining
- [ ] **High CPU**: > 80% for 5 minutes
- [ ] **High Connections**: > 80% of max connections

#### ElastiCache Alarms

- [ ] **High CPU**: > 75% for 5 minutes
- [ ] **High Memory**: DatabaseMemoryUsagePercentage > 90%
- [ ] **High Evictions**: Evictions > 1000 in 5 minutes

### 3. Dashboards

- [ ] **Overview Dashboard**: Key metrics from all services
- [ ] **ECS Dashboard**: Task count, CPU, memory, network
- [ ] **Lambda Dashboard**: Invocations, duration, errors
- [ ] **API Gateway Dashboard**: Request count, latency, errors

## Implementation Details

### Terraform Configuration

```hcl
# Log Groups
resource "aws_cloudwatch_log_group" "ecs_game_service" {
  name              = "/ecs/${var.project_name}-game-service"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda_record_service" {
  name              = "/aws/lambda/${var.project_name}-record-service"
  retention_in_days = 7

  tags = var.tags
}

# ECS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilization above 80%"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.game_service_name
  }

  tags = var.tags
}

# Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Lambda function errors exceeded threshold"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = var.record_service_lambda_name
  }

  tags = var.tags
}

# RDS Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2GB in bytes
  alarm_description   = "RDS free storage space below 2GB"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }],
            [".", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            [".", "Errors", { stat = "Sum" }],
            [".", "Duration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      }
    ]
  })
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
```

## Deployment Steps

```powershell
terraform apply -target=module.cloudwatch -var-file="env/dev.tfvars.local"

# View dashboard
$DASHBOARD_URL = terraform output -raw dashboard_url
Start-Process $DASHBOARD_URL

# Test alarm (trigger high CPU)
# CloudWatch will send SNS notification
```

## Cost Estimation

- **Log Ingestion**: $0.50/GB × 2GB = $1.00
- **Log Storage**: $0.03/GB × 2GB = $0.06
- **Metrics**: $0.30/metric × 10 custom = $3.00
- **Alarms**: Free (first 10 alarms)
- **Dashboards**: $3/dashboard
- **Total**: ~$7/month (can optimize to $3 by reducing logs/dashboards in dev)

## References

- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Log Insights Queries](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
