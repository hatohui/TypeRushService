# Module 02: Security Groups - Outputs

output "alb_security_group_id" {
  description = "Security group ID for internal ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks (Game Service)"
  value       = aws_security_group.ecs.id
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS PostgreSQL"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = aws_security_group.elasticache.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC Interface Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "bastion_security_group_id" {
  description = "Security group ID for bastion host (if created)"
  value       = var.create_bastion ? aws_security_group.bastion[0].id : null
}

output "security_group_summary" {
  description = "Summary of all security groups created"
  value = {
    alb           = aws_security_group.alb.id
    ecs           = aws_security_group.ecs.id
    lambda        = aws_security_group.lambda.id
    rds           = aws_security_group.rds.id
    elasticache   = aws_security_group.elasticache.id
    vpc_endpoints = aws_security_group.vpc_endpoints.id
    bastion       = var.create_bastion ? aws_security_group.bastion[0].id : "not-created"
  }
}
