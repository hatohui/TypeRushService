# ========================================
# CloudWatch Module Outputs
# ========================================

output "dashboard_url" {
  description = "URL to view the CloudWatch dashboard"
  value       = var.create_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : "Dashboard not created"
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : ""
}

output "alarm_arns" {
  description = "ARNs of all created CloudWatch alarms"
  value = concat(
    var.enable_ecs_alarms ? [
      aws_cloudwatch_metric_alarm.ecs_high_cpu[0].arn,
      aws_cloudwatch_metric_alarm.ecs_high_memory[0].arn,
      aws_cloudwatch_metric_alarm.ecs_service_unhealthy[0].arn
    ] : [],
    var.enable_lambda_alarms ? [
      aws_cloudwatch_metric_alarm.record_lambda_errors[0].arn,
      aws_cloudwatch_metric_alarm.record_lambda_duration[0].arn,
      aws_cloudwatch_metric_alarm.text_lambda_errors[0].arn
    ] : [],
    var.enable_rds_alarms ? [
      aws_cloudwatch_metric_alarm.rds_low_storage[0].arn,
      aws_cloudwatch_metric_alarm.rds_high_cpu[0].arn,
      aws_cloudwatch_metric_alarm.rds_high_connections[0].arn
    ] : [],
    var.enable_elasticache_alarms ? [
      aws_cloudwatch_metric_alarm.elasticache_high_cpu[0].arn,
      aws_cloudwatch_metric_alarm.elasticache_high_memory[0].arn,
      aws_cloudwatch_metric_alarm.elasticache_high_evictions[0].arn
    ] : [],
    var.enable_api_gateway_alarms ? [
      aws_cloudwatch_metric_alarm.api_gateway_5xx[0].arn,
      aws_cloudwatch_metric_alarm.api_gateway_latency[0].arn
    ] : []
  )
}
