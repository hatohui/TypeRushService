# ==================================
# ElastiCache Redis Module - Variables
# ==================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==================================
# Network Configuration
# ==================================

variable "cache_subnet_ids" {
  description = "List of cache subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

variable "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache cluster"
  type        = string
}

# ==================================
# ElastiCache Configuration
# ==================================

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.t4g.micro)"
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (1 for single-node dev)"
  type        = number
  default     = 1
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

# ==================================
# Authentication and Encryption
# ==================================

variable "auth_token" {
  description = "AUTH token for Redis authentication (from Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

# ==================================
# Backup and Maintenance
# ==================================

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0 to disable)"
  type        = number
  default     = 0
}

variable "maintenance_window" {
  description = "Maintenance window (format: ddd:hh:mm-ddd:hh:mm)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = false
}

# ==================================
# Monitoring
# ==================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for slow queries"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
