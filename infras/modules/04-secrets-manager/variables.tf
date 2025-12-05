# ==================================
# Secrets Manager Module - Input Variables
# ==================================

variable "project_name" {
  description = "Project name for resource naming and tagging"
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
# Secret Recovery Configuration
# ==================================

variable "secret_recovery_window_days" {
  description = "Number of days to retain deleted secrets (0 for immediate deletion, max 30)"
  type        = number
  default     = 7
  validation {
    condition     = var.secret_recovery_window_days >= 0 && var.secret_recovery_window_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

# ==================================
# RDS PostgreSQL Configuration
# ==================================

variable "rds_master_username" {
  description = "Master username for RDS PostgreSQL"
  type        = string
  default     = "typerush_admin"
}

variable "rds_database_name" {
  description = "Database name for RDS PostgreSQL"
  type        = string
  default     = "typerush_records"
}

variable "rds_port" {
  description = "Port number for RDS PostgreSQL"
  type        = number
  default     = 5432
}

variable "rds_endpoint" {
  description = "RDS endpoint (optional - can be updated after RDS is created)"
  type        = string
  default     = ""
}

variable "rds_instance_id" {
  description = "RDS instance identifier (optional - can be updated after RDS is created)"
  type        = string
  default     = ""
}

# ==================================
# ElastiCache Redis Configuration
# ==================================

variable "elasticache_port" {
  description = "Port number for ElastiCache Redis"
  type        = number
  default     = 6379
}

variable "elasticache_endpoint" {
  description = "ElastiCache endpoint (optional - can be updated after ElastiCache is created)"
  type        = string
  default     = ""
}
