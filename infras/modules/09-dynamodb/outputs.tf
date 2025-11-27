# ==================================
# DynamoDB Module - Outputs
# ==================================

output "texts_table_name" {
  description = "Name of the DynamoDB texts table"
  value       = aws_dynamodb_table.texts.name
}

output "texts_table_arn" {
  description = "ARN of the DynamoDB texts table"
  value       = aws_dynamodb_table.texts.arn
}

output "texts_table_id" {
  description = "ID of the DynamoDB texts table"
  value       = aws_dynamodb_table.texts.id
}

output "texts_table_stream_arn" {
  description = "ARN of the DynamoDB stream (if enabled)"
  value       = try(aws_dynamodb_table.texts.stream_arn, null)
}

output "difficulty_language_index_name" {
  description = "Name of the difficulty-language GSI"
  value       = "difficulty-language-index"
}

output "category_created_index_name" {
  description = "Name of the category-created GSI"
  value       = "category-created-index"
}
