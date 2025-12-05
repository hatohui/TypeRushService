# ========================================
# VPC Link Module Variables
# ========================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ========================================
# Network Configuration
# ========================================

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC Link"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB (used for VPC Link to allow communication with ALB)"
  type        = string
}
