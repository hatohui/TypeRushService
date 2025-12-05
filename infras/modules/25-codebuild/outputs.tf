# ========================================
# CodeBuild Module Outputs
# ========================================

output "game_service_build_name" {
  description = "Name of the Game Service CodeBuild project"
  value       = var.create_game_service_build ? aws_codebuild_project.game_service[0].name : ""
}

output "game_service_build_arn" {
  description = "ARN of the Game Service CodeBuild project"
  value       = var.create_game_service_build ? aws_codebuild_project.game_service[0].arn : ""
}

output "record_service_build_name" {
  description = "Name of the Record Service CodeBuild project"
  value       = var.create_record_service_build ? aws_codebuild_project.record_service[0].name : ""
}

output "record_service_build_arn" {
  description = "ARN of the Record Service CodeBuild project"
  value       = var.create_record_service_build ? aws_codebuild_project.record_service[0].arn : ""
}

output "record_service_migrate_name" {
  description = "Name of the Record Service migration CodeBuild project"
  value       = var.create_record_service_migrate ? aws_codebuild_project.record_service_migrate[0].name : ""
}

output "record_service_migrate_arn" {
  description = "ARN of the Record Service migration CodeBuild project"
  value       = var.create_record_service_migrate ? aws_codebuild_project.record_service_migrate[0].arn : ""
}

output "text_service_build_name" {
  description = "Name of the Text Service CodeBuild project"
  value       = var.create_text_service_build ? aws_codebuild_project.text_service[0].name : ""
}

output "text_service_build_arn" {
  description = "ARN of the Text Service CodeBuild project"
  value       = var.create_text_service_build ? aws_codebuild_project.text_service[0].arn : ""
}

output "frontend_build_name" {
  description = "Name of the Frontend CodeBuild project"
  value       = var.create_frontend_build ? aws_codebuild_project.frontend[0].name : ""
}

output "frontend_build_arn" {
  description = "ARN of the Frontend CodeBuild project"
  value       = var.create_frontend_build ? aws_codebuild_project.frontend[0].arn : ""
}

output "build_projects" {
  description = "Map of all build project names"
  value = {
    game_service           = var.create_game_service_build ? aws_codebuild_project.game_service[0].name : null
    record_service         = var.create_record_service_build ? aws_codebuild_project.record_service[0].name : null
    record_service_migrate = var.create_record_service_migrate ? aws_codebuild_project.record_service_migrate[0].name : null
    text_service           = var.create_text_service_build ? aws_codebuild_project.text_service[0].name : null
    frontend               = var.create_frontend_build ? aws_codebuild_project.frontend[0].name : null
  }
}
