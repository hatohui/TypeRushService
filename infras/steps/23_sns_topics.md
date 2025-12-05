# Step 23: SNS Topics for Alerting

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/22-sns`

## Overview

Create Amazon SNS topics for sending email/SMS alerts when CloudWatch alarms are triggered, providing real-time notifications of infrastructure issues.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: Email notifications for alarms and critical events
- **Subscribers**: Development team email addresses
- **Integration**: CloudWatch alarms, EventBridge rules
- **Cost**: $0.50/1M emails (free for first 1000/month)

## Components to Implement

### 1. Main Alert Topic

- [ ] **Topic Name**: `typerush-dev-alerts`
- [ ] **Protocol**: Email
- [ ] **Subscribers**: Team email addresses
- [ ] **Purpose**: Critical infrastructure alerts

### 2. Deployment Notifications Topic

- [ ] **Topic Name**: `typerush-dev-deployments`
- [ ] **Protocol**: Email
- [ ] **Subscribers**: Deployment notification list
- [ ] **Purpose**: CodePipeline success/failure notifications

### 3. Subscriptions

- [ ] **Email**: alert-recipient@example.com
- [ ] **Confirmation**: Required (AWS sends confirmation email)
- [ ] **Filter Policy**: Optional (filter by severity)

## Implementation Details

### Terraform Configuration

```hcl
# Main Alerts Topic
resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-alerts"
  display_name      = "TypeRush Infrastructure Alerts"
  delivery_policy   = jsonencode({
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
      Name    = "${var.project_name}-alerts-topic"
      Purpose = "Infrastructure alerts"
    }
  )
}

# Email Subscription
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  # Note: Subscription requires manual confirmation via email
}

# Deployment Notifications Topic
resource "aws_sns_topic" "deployments" {
  name         = "${var.project_name}-deployments"
  display_name = "TypeRush Deployment Notifications"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-deployments-topic"
      Purpose = "Deployment notifications"
    }
  )
}

resource "aws_sns_topic_subscription" "deployments_email" {
  topic_arn = aws_sns_topic.deployments.arn
  protocol  = "email"
  endpoint  = var.deployment_notification_email
}

# Topic Policy (allow CloudWatch and EventBridge to publish)
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

# EventBridge Rule for CodePipeline State Changes
resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  name        = "${var.project_name}-pipeline-state-change"
  description = "Capture CodePipeline execution state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["SUCCEEDED", "FAILED"]
      pipeline = [
        "${var.project_name}-game-service-pipeline",
        "${var.project_name}-record-service-pipeline"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "pipeline_sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.deployments.arn

  input_transformer {
    input_paths = {
      pipeline = "$.detail.pipeline"
      state    = "$.detail.state"
      time     = "$.time"
    }
    input_template = <<EOF
{
  "Subject": "Pipeline <pipeline> <state>",
  "Message": "Pipeline: <pipeline>\nState: <state>\nTime: <time>"
}
EOF
  }
}

# Outputs
output "alerts_topic_arn" {
  description = "ARN of the alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "deployments_topic_arn" {
  description = "ARN of the deployments SNS topic"
  value       = aws_sns_topic.deployments.arn
}

output "subscription_confirmation_note" {
  description = "Note about email subscription confirmation"
  value       = "Check your email (${var.alert_email}) and confirm the SNS subscription"
}
```

### Variables

```hcl
variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
}

variable "deployment_notification_email" {
  description = "Email address for deployment notifications"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

## Deployment Steps

### 1. Plan SNS Deployment

```powershell
terraform plan -target=module.sns -var-file="env/dev.tfvars.local"
```

### 2. Deploy SNS Topics

```powershell
terraform apply -target=module.sns -var-file="env/dev.tfvars.local"
```

### 3. Confirm Email Subscription

**Important**: AWS sends a confirmation email to each subscriber.

```
Subject: AWS Notification - Subscription Confirmation

You have chosen to subscribe to the topic:
arn:aws:sns:ap-southeast-1:123456789012:typerush-dev-alerts

To confirm this subscription, click:
https://sns.ap-southeast-1.amazonaws.com/...
```

Click the confirmation link to activate subscription.

### 4. Verify Subscription Status

```powershell
# List subscriptions
aws sns list-subscriptions-by-topic `
  --topic-arn <topic-arn> `
  --region ap-southeast-1

# Check for "SubscriptionArn": "Confirmed" or "PendingConfirmation"
```

### 5. Test SNS Notification

```powershell
# Publish test message
aws sns publish `
  --topic-arn <topic-arn> `
  --subject "Test Alert" `
  --message "This is a test notification from TypeRush infrastructure" `
  --region ap-southeast-1

# Check your email for the test message
```

### 6. Trigger CloudWatch Alarm (Optional)

```powershell
# Manually set alarm state to ALARM to test notification
aws cloudwatch set-alarm-state `
  --alarm-name typerush-dev-ecs-high-cpu `
  --state-value ALARM `
  --state-reason "Testing SNS notification"
```

## Integration with Other Modules

### Dependencies

None (standalone service)

### Used By

1. **Module 22 - CloudWatch**: Alarm notifications
2. **Module 13 - ALB**: Target health alarms
3. **Module 11 - ECS**: Service health alarms
4. **Module 21 - CodePipeline**: Deployment notifications
5. **Module 07 - RDS**: Database alarms

## Validation Checklist

- [ ] SNS topics are created successfully
- [ ] Email subscription confirmation emails received
- [ ] Email subscriptions confirmed (clicked confirmation link)
- [ ] Subscription status shows "Confirmed" (not "PendingConfirmation")
- [ ] Topic policy allows CloudWatch, EventBridge, CodePipeline
- [ ] Test message received successfully
- [ ] CloudWatch alarms can publish to topic
- [ ] EventBridge rules route to topic

## Cost Estimation

### SNS Costs

- **Email Notifications**:
  - First 1,000/month: FREE
  - Additional: $2.00/100,000 emails
- **Dev Usage**: ~50 emails/month = FREE
- **SMS** (if enabled): $0.00645/SMS (not recommended for dev)
- **Total**: **$0.00** (within free tier)

### Cost Optimization

- Use email only (avoid SMS)
- Filter notifications by severity
- Limit alert frequency (use evaluation periods)
- Disable non-critical alarms in dev

## Troubleshooting

### Issue: Email subscription not receiving confirmation

```powershell
# Check spam/junk folder
# Resend subscription invitation:
aws sns subscribe `
  --topic-arn <topic-arn> `
  --protocol email `
  --notification-endpoint your-email@example.com

# Verify email is correct
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>
```

### Issue: Subscription shows "PendingConfirmation"

```
# Must click confirmation link in email
# Confirmation link expires after 3 days
# If expired, delete and recreate subscription:
aws sns unsubscribe --subscription-arn <subscription-arn>

# Then reapply Terraform
terraform apply -target=module.sns
```

### Issue: CloudWatch alarm not sending notifications

```powershell
# Verify alarm has SNS topic ARN configured
aws cloudwatch describe-alarms `
  --alarm-names typerush-dev-ecs-high-cpu

# Verify topic policy allows CloudWatch
aws sns get-topic-attributes --topic-arn <topic-arn>

# Test alarm state change
aws cloudwatch set-alarm-state `
  --alarm-name typerush-dev-ecs-high-cpu `
  --state-value ALARM `
  --state-reason "Manual test"
```

### Issue: Too many notifications (alarm flapping)

```hcl
# Adjust alarm evaluation periods and datapoints
evaluation_periods = 3  # Increased from 2
datapoints_to_alarm = 2  # Alarm after 2 out of 3 periods

# Or increase alarm threshold
threshold = 85  # Increased from 80
```

## References

- [SNS Documentation](https://docs.aws.amazon.com/sns/)
- [Email Notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)
- [Topic Policies](https://docs.aws.amazon.com/sns/latest/dg/sns-access-policy-language-api-permissions-reference.html)
- [EventBridge Integration](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-targets.html)

## Next Steps

After configuring SNS:

1. Confirm all email subscriptions
2. Test each CloudWatch alarm notification
3. Configure EventBridge rules for deployment notifications
4. Set up Slack/MS Teams integration (advanced)
5. Create PagerDuty integration for on-call alerts (production)
6. Document escalation procedures

## Important Notes

- **Email Confirmation Required**: Subscriptions won't work until confirmed
- **Spam Folder**: Check spam if confirmation email not received
- **Multiple Recipients**: Add multiple email subscriptions for redundancy
- **Email Limits**: Cognito default email limit is 50/day, use SES for production
- **Alarm Fatigue**: Configure appropriate thresholds to avoid too many alerts
- **Production**: Consider SMS, PagerDuty, or OpsGenie for critical production alerts
