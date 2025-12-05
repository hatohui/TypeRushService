# ==================================
# Cognito Module Outputs
# ==================================

output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "The endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "The domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.web.id
}

output "user_pool_client_secret" {
  description = "The secret of the Cognito User Pool Client (empty for public clients)"
  value       = ""
  sensitive   = true
}

output "identity_pool_id" {
  description = "The ID of the Cognito Identity Pool (if created)"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.main[0].id : ""
}

output "hosted_ui_url" {
  description = "The URL for Cognito hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}

# Data source for current region
data "aws_region" "current" {}
