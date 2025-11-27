# ==================================
# CodePipeline Module Outputs
# ==================================

# -----------------------------------------------------
# Pipeline Names and ARNs
# -----------------------------------------------------

output "game_service_pipeline_name" {
  description = "Name of the Game Service pipeline"
  value       = var.create_game_service_pipeline ? aws_codepipeline.game_service[0].name : null
}

output "game_service_pipeline_arn" {
  description = "ARN of the Game Service pipeline"
  value       = var.create_game_service_pipeline ? aws_codepipeline.game_service[0].arn : null
}

output "record_service_pipeline_name" {
  description = "Name of the Record Service pipeline"
  value       = var.create_record_service_pipeline ? aws_codepipeline.record_service[0].name : null
}

output "record_service_pipeline_arn" {
  description = "ARN of the Record Service pipeline"
  value       = var.create_record_service_pipeline ? aws_codepipeline.record_service[0].arn : null
}

output "text_service_pipeline_name" {
  description = "Name of the Text Service pipeline"
  value       = var.create_text_service_pipeline ? aws_codepipeline.text_service[0].name : null
}

output "text_service_pipeline_arn" {
  description = "ARN of the Text Service pipeline"
  value       = var.create_text_service_pipeline ? aws_codepipeline.text_service[0].arn : null
}

output "frontend_pipeline_name" {
  description = "Name of the Frontend pipeline"
  value       = var.create_frontend_pipeline ? aws_codepipeline.frontend[0].name : null
}

output "frontend_pipeline_arn" {
  description = "ARN of the Frontend pipeline"
  value       = var.create_frontend_pipeline ? aws_codepipeline.frontend[0].arn : null
}

# -----------------------------------------------------
# Summary
# -----------------------------------------------------

output "pipelines_summary" {
  description = "Summary of all CodePipeline pipelines"
  value = {
    game_service = {
      created = var.create_game_service_pipeline
      name    = var.create_game_service_pipeline ? aws_codepipeline.game_service[0].name : null
    }
    record_service = {
      created = var.create_record_service_pipeline
      name    = var.create_record_service_pipeline ? aws_codepipeline.record_service[0].name : null
    }
    text_service = {
      created = var.create_text_service_pipeline
      name    = var.create_text_service_pipeline ? aws_codepipeline.text_service[0].name : null
    }
    frontend = {
      created = var.create_frontend_pipeline
      name    = var.create_frontend_pipeline ? aws_codepipeline.frontend[0].name : null
    }
  }
}
