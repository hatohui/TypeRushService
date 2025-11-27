# ==================================
# ElastiCache Redis Module - Outputs
# ==================================

output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.redis.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address for Redis (for single-node or cluster mode disabled)"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for Redis (available when replicas exist)"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address (for cluster mode enabled)"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "redis_connection_string" {
  description = "Redis connection string with TLS (use with AUTH token from Secrets Manager)"
  value       = "rediss://default:AUTH_TOKEN@${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
  sensitive   = false # Connection string without actual token
}

output "redis_connection_info" {
  description = "Redis connection information for ECS environment variables"
  value = {
    host = aws_elasticache_replication_group.redis.primary_endpoint_address
    port = aws_elasticache_replication_group.redis.port
    tls  = true
  }
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}

output "engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_replication_group.redis.engine_version_actual
}

output "node_type" {
  description = "Redis node type"
  value       = aws_elasticache_replication_group.redis.node_type
}

output "num_cache_clusters" {
  description = "Number of cache clusters"
  value       = aws_elasticache_replication_group.redis.num_cache_clusters
}

output "member_clusters" {
  description = "List of member cluster IDs"
  value       = aws_elasticache_replication_group.redis.member_clusters
}
