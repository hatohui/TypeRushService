# ==================================
# ElastiCache Redis Module - Main Resources
# ==================================

# ==================================
# ElastiCache Subnet Group
# ==================================

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "Subnet group for ${var.project_name} ${var.environment} Redis cluster"
  subnet_ids  = var.cache_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-subnet-group"
    }
  )
}

# ==================================
# ElastiCache Parameter Group (Optional - using default for dev)
# ==================================

# Uncomment if custom parameters are needed
# resource "aws_elasticache_parameter_group" "redis" {
#   name   = "${var.project_name}-${var.environment}-redis-params"
#   family = var.parameter_group_family
#
#   # Example parameters for production
#   parameter {
#     name  = "maxmemory-policy"
#     value = "allkeys-lru"
#   }
#
#   parameter {
#     name  = "timeout"
#     value = "300"
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-${var.environment}-redis-params"
#     }
#   )
# }

# ==================================
# CloudWatch Log Group (Optional)
# ==================================

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/elasticache/${var.project_name}-${var.environment}-redis/slow-log"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-slow-log"
    }
  )
}

# ==================================
# ElastiCache Replication Group (Redis Cluster)
# ==================================

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "TypeRush ${var.environment} game session cache"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = var.port
  parameter_group_name = "default.${var.parameter_group_family}"

  # Authentication and Encryption
  auth_token                 = var.auth_token
  auth_token_update_strategy = "SET"
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = "required"
  at_rest_encryption_enabled = var.at_rest_encryption_enabled

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.elasticache_security_group_id]

  # Availability
  automatic_failover_enabled = false # Single-node, no failover
  multi_az_enabled           = false # Single-AZ for dev

  # Backup configuration
  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = "02:00-03:00" # Before maintenance window
  final_snapshot_identifier = var.snapshot_retention_limit > 0 ? "${var.project_name}-${var.environment}-redis-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}" : null

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Notifications (optional)
  # notification_topic_arn = var.sns_topic_arn

  # Log delivery configuration (optional)
  dynamic "log_delivery_configuration" {
    for_each = var.enable_cloudwatch_logs ? [1] : []

    content {
      destination      = aws_cloudwatch_log_group.redis_slow_log[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-redis"
      Purpose = "Game session state"
      Service = "Game Service"
    }
  )

  # Lifecycle to prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true in production
    ignore_changes = [
      final_snapshot_identifier # Prevent changes on every apply
    ]
  }
}
