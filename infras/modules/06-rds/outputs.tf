# ==================================
# RDS Module - Outputs
# ==================================

# ==================================
# Instance Information
# ==================================

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.record_db.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.record_db.arn
}

output "db_instance_resource_id" {
  description = "Resource ID of the RDS instance"
  value       = aws_db_instance.record_db.resource_id
}

output "db_instance_status" {
  description = "Status of the RDS instance"
  value       = aws_db_instance.record_db.status
}

# ==================================
# Connection Information
# ==================================

output "db_instance_endpoint" {
  description = "Connection endpoint (host:port format)"
  value       = aws_db_instance.record_db.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.record_db.address
}

output "db_instance_port" {
  description = "Port the database is listening on"
  value       = aws_db_instance.record_db.port
}

output "db_instance_hosted_zone_id" {
  description = "Hosted zone ID for the RDS instance"
  value       = aws_db_instance.record_db.hosted_zone_id
}

# ==================================
# Database Information
# ==================================

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.record_db.db_name
}

output "db_username" {
  description = "Master username for the database"
  value       = aws_db_instance.record_db.username
  sensitive   = true
}

output "db_engine" {
  description = "Database engine"
  value       = aws_db_instance.record_db.engine
}

output "db_engine_version" {
  description = "Database engine version"
  value       = aws_db_instance.record_db.engine_version_actual
}

# ==================================
# Subnet Group Information
# ==================================

output "db_subnet_group_id" {
  description = "DB subnet group identifier"
  value       = aws_db_subnet_group.record_db.id
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.record_db.arn
}

# ==================================
# Parameter Group Information
# ==================================

output "db_parameter_group_id" {
  description = "DB parameter group identifier"
  value       = length(var.parameters) > 0 ? aws_db_parameter_group.record_db[0].id : null
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = length(var.parameters) > 0 ? aws_db_parameter_group.record_db[0].arn : null
}

# ==================================
# Connection String (for documentation)
# ==================================

output "connection_string_format" {
  description = "Format for PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.record_db.username}:<PASSWORD>@${aws_db_instance.record_db.address}:${aws_db_instance.record_db.port}/${aws_db_instance.record_db.db_name}?sslmode=require"
  sensitive   = true
}

# ==================================
# CloudWatch Log Groups
# ==================================

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for RDS logs"
  value = [
    for log_type in var.enabled_cloudwatch_logs_exports :
    "/aws/rds/instance/${aws_db_instance.record_db.identifier}/${log_type}"
  ]
}

# ==================================
# Backup Information
# ==================================

output "backup_retention_period" {
  description = "Number of days automated backups are retained"
  value       = aws_db_instance.record_db.backup_retention_period
}

output "backup_window" {
  description = "Backup window"
  value       = aws_db_instance.record_db.backup_window
}

output "maintenance_window" {
  description = "Maintenance window"
  value       = aws_db_instance.record_db.maintenance_window
}

# ==================================
# Security Information
# ==================================

output "storage_encrypted" {
  description = "Whether storage encryption is enabled"
  value       = aws_db_instance.record_db.storage_encrypted
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = aws_db_instance.record_db.kms_key_id
}

output "ca_cert_identifier" {
  description = "CA certificate identifier"
  value       = aws_db_instance.record_db.ca_cert_identifier
}
