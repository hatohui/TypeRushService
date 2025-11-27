# ==================================
# Route 53 Module Outputs
# ==================================

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.domain_name != "" ? local.zone_id : ""
}

output "name_servers" {
  description = "Name servers for the hosted zone (if created)"
  value       = var.create_route53_zone && var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}

output "domain_name" {
  description = "Domain name configured in Route 53"
  value       = var.domain_name
}

output "health_check_id" {
  description = "Route 53 health check ID (if enabled)"
  value       = var.enable_health_check && var.domain_name != "" ? aws_route53_health_check.main[0].id : ""
}
