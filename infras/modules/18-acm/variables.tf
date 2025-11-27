# ==================================
# ACM Module Variables
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
  description = "Primary domain name for SSL certificate (leave empty to skip certificate creation)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation (leave empty for manual validation)"
  type        = string
  default     = ""
}

variable "use_api_custom_domain" {
  description = "Whether to create API Gateway custom domain certificate (ap-southeast-1)"
  type        = bool
  default     = false
}

variable "enable_cert_expiry_alarm" {
  description = "Enable CloudWatch alarm for certificate expiry"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for certificate expiry alarms (optional)"
  type        = string
  default     = ""
}
