# ========================================
# Outputs for Internal ALB
# ========================================

output "alb_id" {
  description = "ID of the internal ALB"
  value       = aws_lb.internal.id
}

output "alb_arn" {
  description = "ARN of the internal ALB"
  value       = aws_lb.internal.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the internal ALB (for CloudWatch metrics)"
  value       = aws_lb.internal.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.internal.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the internal ALB (for Route53 alias records)"
  value       = aws_lb.internal.zone_id
}

output "target_group_arn" {
  description = "ARN of the Game Service target group"
  value       = aws_lb_target_group.game_service.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the Game Service target group (for CloudWatch metrics)"
  value       = aws_lb_target_group.game_service.arn_suffix
}

output "target_group_name" {
  description = "Name of the Game Service target group"
  value       = aws_lb_target_group.game_service.name
}

output "listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "listener_id" {
  description = "ID of the HTTP listener"
  value       = aws_lb_listener.http.id
}
