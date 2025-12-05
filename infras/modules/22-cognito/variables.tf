# ==================================
# Cognito Module Variables
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

variable "cognito_domain_suffix" {
  description = "Suffix for Cognito hosted UI domain (must be globally unique)"
  type        = string
  default     = "auth"
}

variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 8
}

variable "enable_mfa" {
  description = "Enable MFA for user pool"
  type        = bool
  default     = false
}

variable "callback_urls" {
  description = "List of callback URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of logout URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/"]
}

variable "create_identity_pool" {
  description = "Whether to create Cognito Identity Pool for AWS credentials"
  type        = bool
  default     = false
}
