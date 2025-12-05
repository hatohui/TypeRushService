# ========================================
# HTTP API Module Variables
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
# VPC Link Configuration
# ========================================

variable "vpc_link_id" {
  description = "ID of the VPC Link for ALB integration"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for Game Service integration"
  type        = string
}

# ========================================
# Lambda Configuration
# ========================================

variable "record_service_lambda_invoke_arn" {
  description = "Invoke ARN of the Record Service Lambda function"
  type        = string
}

variable "record_service_lambda_name" {
  description = "Name of the Record Service Lambda function"
  type        = string
}

variable "text_service_lambda_invoke_arn" {
  description = "Invoke ARN of the Text Service Lambda function"
  type        = string
}

variable "text_service_lambda_name" {
  description = "Name of the Text Service Lambda function"
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

variable "cors_allow_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
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
