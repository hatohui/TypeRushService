# ==================================
# VPC Endpoints Module - Outputs
# ==================================

# ==================================
# Interface Endpoints
# ==================================

output "secretsmanager_endpoint_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "secretsmanager_endpoint_dns_entries" {
  description = "DNS entries for Secrets Manager VPC endpoint"
  value       = aws_vpc_endpoint.secretsmanager.dns_entry
}

output "bedrock_runtime_endpoint_id" {
  description = "ID of the Bedrock Runtime VPC endpoint"
  value       = aws_vpc_endpoint.bedrock_runtime.id
}

output "bedrock_runtime_endpoint_dns_entries" {
  description = "DNS entries for Bedrock Runtime VPC endpoint"
  value       = aws_vpc_endpoint.bedrock_runtime.dns_entry
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_api_endpoint_dns_entries" {
  description = "DNS entries for ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.dns_entry
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR Docker VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "ecr_dkr_endpoint_dns_entries" {
  description = "DNS entries for ECR Docker VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.dns_entry
}

# ==================================
# Gateway Endpoints
# ==================================

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID for S3 Gateway endpoint (for security group rules)"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID for DynamoDB Gateway endpoint (for security group rules)"
  value       = aws_vpc_endpoint.dynamodb.prefix_list_id
}

# ==================================
# Combined Outputs
# ==================================

output "all_interface_endpoint_ids" {
  description = "List of all interface endpoint IDs"
  value = [
    aws_vpc_endpoint.secretsmanager.id,
    aws_vpc_endpoint.bedrock_runtime.id,
    aws_vpc_endpoint.ecr_api.id,
    aws_vpc_endpoint.ecr_dkr.id
  ]
}

output "all_gateway_endpoint_ids" {
  description = "List of all gateway endpoint IDs"
  value = [
    aws_vpc_endpoint.s3.id,
    aws_vpc_endpoint.dynamodb.id
  ]
}

output "endpoint_summary" {
  description = "Summary of all VPC endpoints created"
  value = {
    interface_endpoints = {
      secretsmanager  = aws_vpc_endpoint.secretsmanager.id
      bedrock_runtime = aws_vpc_endpoint.bedrock_runtime.id
      ecr_api         = aws_vpc_endpoint.ecr_api.id
      ecr_dkr         = aws_vpc_endpoint.ecr_dkr.id
    }
    gateway_endpoints = {
      s3       = aws_vpc_endpoint.s3.id
      dynamodb = aws_vpc_endpoint.dynamodb.id
    }
    total_interface_cost = "$28.80/month"
    total_gateway_cost   = "FREE"
  }
}
