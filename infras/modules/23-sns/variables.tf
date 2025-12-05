# ========================================
# SNS Module Variables
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

variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
  default     = ""
}

variable "deployment_notification_email" {
  description = "Email address for deployment notifications (defaults to alert_email if not specified)"
  type        = string
  default     = ""
}

variable "enable_pipeline_notifications" {
  description = "Enable EventBridge rules for pipeline state change notifications"
  type        = bool
  default     = false
}
