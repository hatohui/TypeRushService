# ========================================
# CloudWatch Module Variables
# ========================================

variable "project_name" {
  description = "Project name for resource naming"
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

variable "sns_topic_arn" {
  description = "ARN of SNS topic for alarm notifications"
  type        = string
}

# ========================================
# Feature Flags
# ========================================

variable "enable_ecs_alarms" {
  description = "Enable CloudWatch alarms for ECS service"
  type        = bool
  default     = true
}

variable "enable_lambda_alarms" {
  description = "Enable CloudWatch alarms for Lambda functions"
  type        = bool
  default     = true
}

variable "enable_rds_alarms" {
  description = "Enable CloudWatch alarms for RDS"
  type        = bool
  default     = true
}

variable "enable_elasticache_alarms" {
  description = "Enable CloudWatch alarms for ElastiCache"
  type        = bool
  default     = true
}

variable "enable_api_gateway_alarms" {
  description = "Enable CloudWatch alarms for API Gateway"
  type        = bool
  default     = true
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

# ========================================
# ECS Configuration
# ========================================

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = ""
}

# ========================================
# Lambda Configuration
# ========================================

variable "record_lambda_name" {
  description = "Name of the Record Service Lambda function"
  type        = string
  default     = ""
}

variable "text_lambda_name" {
  description = "Name of the Text Service Lambda function"
  type        = string
  default     = ""
}

# ========================================
# RDS Configuration
# ========================================

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
  default     = ""
}

# ========================================
# ElastiCache Configuration
# ========================================

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster identifier"
  type        = string
  default     = ""
}

# ========================================
# API Gateway Configuration
# ========================================

variable "api_gateway_id" {
  description = "API Gateway ID for alarms"
  type        = string
  default     = ""
}
