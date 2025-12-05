# ========================================
# Lambda Module Outputs
# ========================================

# ========================================
# Record Service Outputs
# ========================================

output "record_service_function_name" {
  description = "Name of the Record Service Lambda function"
  value       = aws_lambda_function.record_service.function_name
}

output "record_service_function_arn" {
  description = "ARN of the Record Service Lambda function"
  value       = aws_lambda_function.record_service.arn
}

output "record_service_invoke_arn" {
  description = "Invoke ARN of the Record Service Lambda function (for API Gateway integration)"
  value       = aws_lambda_function.record_service.invoke_arn
}

output "record_service_qualified_arn" {
  description = "Qualified ARN of the Record Service Lambda function (includes version)"
  value       = aws_lambda_function.record_service.qualified_arn
}

output "record_service_log_group_name" {
  description = "Name of the CloudWatch Log Group for Record Service"
  value       = aws_cloudwatch_log_group.record_service.name
}

# ========================================
# Text Service Outputs
# ========================================

output "text_service_function_name" {
  description = "Name of the Text Service Lambda function"
  value       = aws_lambda_function.text_service.function_name
}

output "text_service_function_arn" {
  description = "ARN of the Text Service Lambda function"
  value       = aws_lambda_function.text_service.arn
}

output "text_service_invoke_arn" {
  description = "Invoke ARN of the Text Service Lambda function (for API Gateway integration)"
  value       = aws_lambda_function.text_service.invoke_arn
}

output "text_service_qualified_arn" {
  description = "Qualified ARN of the Text Service Lambda function (includes version)"
  value       = aws_lambda_function.text_service.qualified_arn
}

output "text_service_log_group_name" {
  description = "Name of the CloudWatch Log Group for Text Service"
  value       = aws_cloudwatch_log_group.text_service.name
}
