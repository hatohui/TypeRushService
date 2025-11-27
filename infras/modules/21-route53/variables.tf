# ==================================
# Route 53 Module Variables
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

variable "domain_name" {
  description = "Primary domain name (e.g., typerush.example.com). Leave empty to skip Route 53 setup."
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Whether to create a new Route 53 hosted zone. Set to false to use an existing zone."
  type        = bool
  default     = false
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for alias records"
  type        = string
  default     = ""
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2 for CloudFront)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "api_gateway_custom_domain" {
  description = "API Gateway custom domain name for CNAME record"
  type        = string
  default     = ""
}

variable "ws_gateway_custom_domain" {
  description = "WebSocket API Gateway custom domain name for CNAME record"
  type        = string
  default     = ""
}

variable "enable_health_check" {
  description = "Enable Route 53 health checks"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check request interval in seconds (10 or 30)"
  type        = number
  default     = 30
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive failures before marking unhealthy"
  type        = number
  default     = 3
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for health check alarms"
  type        = string
  default     = ""
}
