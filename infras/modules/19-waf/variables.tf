# ==================================
# WAF Module Variables
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

variable "enable_waf" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 7
}

variable "rate_limit_general" {
  description = "General rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "rate_limit_api" {
  description = "API rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 500
}

variable "blocked_countries" {
  description = "List of country codes to block (e.g., ['CN', 'RU']). Empty list disables geo blocking."
  type        = list(string)
  default     = []
}
