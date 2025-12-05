# ==================================
# DynamoDB Module - Input Variables
# ==================================

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

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery for the DynamoDB table"
  type        = bool
  default     = false
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection for the DynamoDB table"
  type        = bool
  default     = false
}
