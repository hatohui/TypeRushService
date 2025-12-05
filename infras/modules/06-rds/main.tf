# ==================================
# RDS Module - PostgreSQL Database
# ==================================

# ==================================
# DB Subnet Group
# ==================================

resource "aws_db_subnet_group" "record_db" {
  name        = "${var.project_name}-${var.environment}-record-db-subnet-group"
  description = "Database subnet group for ${var.project_name} Record DB"
  subnet_ids  = var.database_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-record-db-subnet-group"
    }
  )
}

# ==================================
# DB Parameter Group (Optional custom parameters)
# ==================================

resource "aws_db_parameter_group" "record_db" {
  count = length(var.parameters) > 0 ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-record-db-"
  family      = var.parameter_family
  description = "Custom parameter group for ${var.project_name} Record DB"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-record-db-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================
# RDS PostgreSQL Instance
# ==================================

resource "aws_db_instance" "record_db" {
  # Instance identification
  identifier = "${var.project_name}-${var.environment}-record-db"

  # Engine configuration
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  license_model  = "postgresql-license"

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  # Use default KMS key (aws/rds) for encryption
  # kms_key_id can be specified for custom KMS key

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.database_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.record_db.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # Parameter group
  parameter_group_name = length(var.parameters) > 0 ? aws_db_parameter_group.record_db[0].name : "default.${var.parameter_family}"

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot

  # Snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-${var.final_snapshot_identifier_prefix}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

  # Monitoring and logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  # performance_insights_kms_key_id can be specified for custom KMS key

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately (dev environment)
  # Set to false in production to apply during maintenance window
  apply_immediately = var.environment != "prod"

  # Allow major version upgrades (must be done manually)
  allow_major_version_upgrade = false

  # CA certificate identifier (optional)
  # ca_cert_identifier = "rds-ca-rsa2048-g1"

  # IAM database authentication (disabled for password-based auth)
  iam_database_authentication_enabled = false

  tags = merge(
    var.tags,
    {
      Name     = "${var.project_name}-${var.environment}-record-db"
      Database = var.database_name
      Engine   = "PostgreSQL"
      Version  = var.engine_version
    }
  )

  # Prevent accidental deletion of database during terraform destroy
  lifecycle {
    prevent_destroy = false # Set to true in production
    ignore_changes = [
      # Ignore password changes as it's managed by Secrets Manager rotation
      password,
      # Ignore final snapshot identifier as it's generated with timestamp
      final_snapshot_identifier,
    ]
  }

  # Ensure subnet group is created first
  depends_on = [
    aws_db_subnet_group.record_db
  ]
}
