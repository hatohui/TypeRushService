# Module 02: Security Groups - Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "game_service_port" {
  description = "Port for Game Service container"
  type        = number
  default     = 3000
}

variable "elasticache_port" {
  description = "Redis port for ElastiCache"
  type        = number
  default     = 6379
}

variable "create_bastion" {
  description = "Whether to create bastion security group"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH to bastion"
  type        = string
  default     = "0.0.0.0/32" # No access by default
}
