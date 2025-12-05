# ==================================
# Secrets Manager Module - Random Passwords and Secrets
# ==================================
# This module creates AWS Secrets Manager secrets for:
# - RDS PostgreSQL database credentials
# - ElastiCache Redis AUTH token
# Uses Terraform random provider for secure password generation

# Random provider is configured in the root terraform.tf
# This module inherits the random provider from the root module

# ==================================
# Random Password Generation
# ==================================

# Generate random password for RDS PostgreSQL
resource "random_password" "rds_password" {
  length  = 32
  special = true
  # Exclude problematic characters for PostgreSQL connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Generate random AUTH token for ElastiCache Redis
# Note: ElastiCache requires alphanumeric characters only
resource "random_password" "redis_auth_token" {
  length      = 64
  special     = false # ElastiCache AUTH tokens must be alphanumeric only
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

# ==================================
# RDS PostgreSQL Credentials Secret
# ==================================

# Create the secret metadata
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}/${var.environment}/record-db/credentials-${substr(md5("${timestamp()}"), 0, 8)}"
  description             = "RDS PostgreSQL credentials for Record Service"
  recovery_window_in_days = 0  # Allow immediate recreation during development

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-rds-credentials"
      Purpose = "RDS PostgreSQL connection credentials"
      Service = "record-service"
    }
  )
}

# Store the secret value (JSON format)
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username            = var.rds_master_username
    password            = random_password.rds_password.result
    engine              = "postgres"
    host                = var.rds_endpoint != "" ? var.rds_endpoint : "placeholder-will-be-updated"
    port                = var.rds_port
    dbname              = var.rds_database_name
    dbClusterIdentifier = var.rds_instance_id != "" ? var.rds_instance_id : "placeholder-will-be-updated"
  })
}

# ==================================
# ElastiCache Redis AUTH Token Secret
# ==================================

# Create the secret metadata
resource "aws_secretsmanager_secret" "elasticache_auth_token" {
  name                    = "${var.project_name}/${var.environment}/elasticache/auth-token-${substr(md5("${timestamp()}"), 0, 8)}"
  description             = "ElastiCache Redis AUTH token for Game Service"
  recovery_window_in_days = 0  # Allow immediate recreation during development

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-elasticache-auth-token"
      Purpose = "ElastiCache Redis AUTH token"
      Service = "game-service"
    }
  )
}

# Store the secret value (JSON format)
resource "aws_secretsmanager_secret_version" "elasticache_auth_token" {
  secret_id = aws_secretsmanager_secret.elasticache_auth_token.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
    endpoint   = var.elasticache_endpoint != "" ? var.elasticache_endpoint : "placeholder-will-be-updated"
    port       = var.elasticache_port
  })
}
