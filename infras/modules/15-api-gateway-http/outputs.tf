# ========================================
# HTTP API Module Outputs
# ========================================

output "http_api_id" {
  description = "ID of the HTTP API"
  value       = aws_apigatewayv2_api.http.id
}

output "http_api_arn" {
  description = "ARN of the HTTP API"
  value       = aws_apigatewayv2_api.http.arn
}

output "http_api_endpoint" {
  description = "Default endpoint URL of the HTTP API"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "http_api_execution_arn" {
  description = "Execution ARN of the HTTP API"
  value       = aws_apigatewayv2_api.http.execution_arn
}

output "http_stage_invoke_url" {
  description = "Full invoke URL for the HTTP API stage"
  value       = aws_apigatewayv2_stage.http_dev.invoke_url
}

output "http_stage_id" {
  description = "ID of the HTTP API stage"
  value       = aws_apigatewayv2_stage.http_dev.id
}
