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

# Network Configuration
variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# IAM Roles
variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN (for ECR and CloudWatch)"
  type        = string
}

variable "game_service_task_role_arn" {
  description = "Game Service task role ARN (for application permissions)"
  type        = string
}

# ECR Configuration
variable "game_service_ecr_url" {
  description = "ECR repository URL for Game Service"
  type        = string
}

# ElastiCache Configuration
variable "redis_endpoint" {
  description = "ElastiCache Redis endpoint address"
  type        = string
}

variable "redis_secret_arn" {
  description = "Secrets Manager ARN for Redis auth token"
  type        = string
}

# Load Balancer Configuration
variable "game_service_target_group_arn" {
  description = "ALB target group ARN for Game Service"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN (for dependency)"
  type        = string
}

# Task Configuration
variable "game_service_cpu" {
  description = "CPU units for Game Service task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "game_service_memory" {
  description = "Memory for Game Service task in MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Auto-scaling Configuration
variable "game_service_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "game_service_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 2
}

variable "game_service_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}
