# ========================================
# SNS Topics for TypeRush Alerting
# ========================================

# Main Alerts Topic for Infrastructure
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-${var.environment}-alerts"
  display_name = "TypeRush Infrastructure Alerts"

  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
    }
  })

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-alerts-topic"
      Purpose = "Infrastructure alerts"
    }
  )
}

# Email Subscription for Alerts Topic
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  # Note: Subscription requires manual confirmation via email
}

# Topic Policy - Allow CloudWatch, EventBridge, and CodePipeline to Publish
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "AllowCodePipelinePublish"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# Deployment Notifications Topic
resource "aws_sns_topic" "deployments" {
  name         = "${var.project_name}-${var.environment}-deployments"
  display_name = "TypeRush Deployment Notifications"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-deployments-topic"
      Purpose = "Deployment notifications"
    }
  )
}

# Email Subscription for Deployments Topic
resource "aws_sns_topic_subscription" "deployments_email" {
  count     = var.deployment_notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.deployments.arn
  protocol  = "email"
  endpoint  = var.deployment_notification_email
}

# Topic Policy for Deployments Topic
resource "aws_sns_topic_policy" "deployments" {
  arn = aws_sns_topic.deployments.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.deployments.arn
      },
      {
        Sid    = "AllowCodePipelinePublish"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.deployments.arn
      }
    ]
  })
}

# EventBridge Rule for CodePipeline State Changes
resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  count       = var.enable_pipeline_notifications ? 1 : 0
  name        = "${var.project_name}-${var.environment}-pipeline-state-change"
  description = "Capture CodePipeline execution state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["SUCCEEDED", "FAILED"]
      pipeline = [
        "${var.project_name}-${var.environment}-game-service-pipeline",
        "${var.project_name}-${var.environment}-record-service-pipeline",
        "${var.project_name}-${var.environment}-text-service-pipeline",
        "${var.project_name}-${var.environment}-frontend-pipeline"
      ]
    }
  })

  tags = var.tags
}

# EventBridge Target - Send to SNS
resource "aws_cloudwatch_event_target" "pipeline_sns" {
  count     = var.enable_pipeline_notifications ? 1 : 0
  rule      = aws_cloudwatch_event_rule.pipeline_state_change[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.deployments.arn

  input_transformer {
    input_paths = {
      pipeline = "$.detail.pipeline"
      state    = "$.detail.state"
      time     = "$.time"
    }
    input_template = <<EOF
Pipeline: <pipeline>
State: <state>
Time: <time>
EOF
  }
}
