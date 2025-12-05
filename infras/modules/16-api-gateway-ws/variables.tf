# ========================================
# WebSocket API Module Variables
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
# ALB Configuration
# ========================================
# Note: WebSocket APIs do NOT support VPC Link V2
# Using direct INTERNET connection to ALB DNS

variable "alb_dns_name" {
  description = "DNS name of the ALB for Game Service WebSocket integration (must be publicly accessible)"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for Game Service integration (for reference)"
  type        = string
}

# ========================================
# API Configuration
# ========================================

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 200
}

variable "enable_data_trace" {
  description = "Enable data trace logging for WebSocket routes"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for WebSocket API (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}
