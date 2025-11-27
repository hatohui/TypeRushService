# ==================================
# Secrets Manager Module - Outputs
# ==================================

# ==================================
# RDS PostgreSQL Secrets
# ==================================

output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "rds_secret_id" {
  description = "ID of the RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.id
}

output "rds_secret_name" {
  description = "Name of the RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "rds_master_password" {
  description = "Generated master password for RDS (sensitive)"
  value       = random_password.rds_password.result
  sensitive   = true
}

output "rds_master_username" {
  description = "Master username for RDS"
  value       = var.rds_master_username
}

output "rds_database_name" {
  description = "Database name for RDS"
  value       = var.rds_database_name
}

# ==================================
# ElastiCache Redis Secrets
# ==================================

output "elasticache_secret_arn" {
  description = "ARN of the ElastiCache AUTH token secret"
  value       = aws_secretsmanager_secret.elasticache_auth_token.arn
}

output "elasticache_secret_id" {
  description = "ID of the ElastiCache AUTH token secret"
  value       = aws_secretsmanager_secret.elasticache_auth_token.id
}

output "elasticache_secret_name" {
  description = "Name of the ElastiCache AUTH token secret"
  value       = aws_secretsmanager_secret.elasticache_auth_token.name
}

output "elasticache_auth_token" {
  description = "Generated AUTH token for ElastiCache (sensitive)"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

# ==================================
# Combined Outputs for IAM Policies
# ==================================

output "all_secret_arns" {
  description = "List of all secret ARNs for IAM policy attachment"
  value = [
    aws_secretsmanager_secret.rds_credentials.arn,
    aws_secretsmanager_secret.elasticache_auth_token.arn
  ]
}
