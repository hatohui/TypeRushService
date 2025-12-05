# ========================================
# WebSocket API Module Outputs
# ========================================

output "websocket_api_id" {
  description = "ID of the WebSocket API"
  value       = aws_apigatewayv2_api.websocket.id
}

output "websocket_api_arn" {
  description = "ARN of the WebSocket API"
  value       = aws_apigatewayv2_api.websocket.arn
}

output "websocket_api_endpoint" {
  description = "Default endpoint URL of the WebSocket API"
  value       = aws_apigatewayv2_api.websocket.api_endpoint
}

output "websocket_api_execution_arn" {
  description = "Execution ARN of the WebSocket API"
  value       = aws_apigatewayv2_api.websocket.execution_arn
}

output "websocket_stage_invoke_url" {
  description = "Full invoke URL for the WebSocket API stage"
  value       = aws_apigatewayv2_stage.ws_dev.invoke_url
}

output "websocket_stage_id" {
  description = "ID of the WebSocket API stage"
  value       = aws_apigatewayv2_stage.ws_dev.id
}

output "websocket_deployment_id" {
  description = "ID of the WebSocket API deployment"
  value       = aws_apigatewayv2_deployment.ws.id
}
