# ========================================
# SNS Module Outputs
# ========================================

output "alerts_topic_arn" {
  description = "ARN of the alerts SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "alerts_topic_name" {
  description = "Name of the alerts SNS topic"
  value       = aws_sns_topic.alerts.name
}

output "deployments_topic_arn" {
  description = "ARN of the deployments SNS topic for pipeline notifications"
  value       = aws_sns_topic.deployments.arn
}

output "deployments_topic_name" {
  description = "Name of the deployments SNS topic"
  value       = aws_sns_topic.deployments.name
}

output "subscription_confirmation_note" {
  description = "Note about email subscription confirmation"
  value       = var.alert_email != "" ? "Check your email (${var.alert_email}) and confirm the SNS subscription" : "No email subscriptions configured"
}
