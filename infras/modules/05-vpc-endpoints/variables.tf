# ==================================
# VPC Endpoints Module - Input Variables
# ==================================

variable "project_name" {
  description = "Project name for resource naming and tagging"
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

# ==================================
# VPC Configuration
# ==================================

variable "vpc_id" {
  description = "VPC ID where endpoints will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for interface endpoints"
  type        = list(string)
}

# ==================================
# Security Groups
# ==================================

variable "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC interface endpoints"
  type        = string
}

# ==================================
# Route Tables (for Gateway Endpoints)
# ==================================

variable "private_route_table_id" {
  description = "Private route table ID for gateway endpoint association"
  type        = string
}

variable "database_route_table_id" {
  description = "Database route table ID for gateway endpoint association"
  type        = string
}

variable "cache_route_table_id" {
  description = "Cache route table ID for gateway endpoint association"
  type        = string
}
