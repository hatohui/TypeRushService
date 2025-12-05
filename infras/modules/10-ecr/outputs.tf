# ========================================
# Outputs for ECR Repositories
# ========================================

# Game Service Repository Outputs
output "game_service_repository_url" {
  description = "URL of the Game Service ECR repository"
  value       = aws_ecr_repository.game_service.repository_url
}

output "game_service_repository_arn" {
  description = "ARN of the Game Service ECR repository"
  value       = aws_ecr_repository.game_service.arn
}

output "game_service_repository_name" {
  description = "Name of the Game Service ECR repository"
  value       = aws_ecr_repository.game_service.name
}

# Record Service Repository Outputs
output "record_service_repository_url" {
  description = "URL of the Record Service ECR repository"
  value       = aws_ecr_repository.record_service.repository_url
}

output "record_service_repository_arn" {
  description = "ARN of the Record Service ECR repository"
  value       = aws_ecr_repository.record_service.arn
}

output "record_service_repository_name" {
  description = "Name of the Record Service ECR repository"
  value       = aws_ecr_repository.record_service.name
}

# Registry ID (AWS Account)
output "registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = aws_ecr_repository.game_service.registry_id
}
