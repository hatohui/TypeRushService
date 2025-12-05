# ==================================
# WAF Module Outputs
# ==================================

output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : ""
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : ""
}

output "web_acl_capacity" {
  description = "The capacity units used by the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].capacity : 0
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for WAF logs"
  value       = var.enable_waf && var.enable_waf_logging ? aws_cloudwatch_log_group.waf[0].name : ""
}
