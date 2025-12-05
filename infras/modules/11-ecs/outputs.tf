# ========================================
# Outputs for ECS Cluster and Service
# ========================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "game_service_name" {
  description = "Name of the Game Service ECS service"
  value       = aws_ecs_service.game_service.name
}

output "game_service_id" {
  description = "ID of the Game Service ECS service"
  value       = aws_ecs_service.game_service.id
}

output "task_definition_arn" {
  description = "ARN of the Game Service task definition"
  value       = aws_ecs_task_definition.game_service.arn
}

output "task_definition_family" {
  description = "Family of the Game Service task definition"
  value       = aws_ecs_task_definition.game_service.family
}

output "task_definition_revision" {
  description = "Revision of the Game Service task definition"
  value       = aws_ecs_task_definition.game_service.revision
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for Game Service"
  value       = aws_cloudwatch_log_group.game_service.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for Game Service"
  value       = aws_cloudwatch_log_group.game_service.arn
}

output "autoscaling_target_id" {
  description = "ID of the auto-scaling target"
  value       = aws_appautoscaling_target.game_service.id
}

output "autoscaling_policy_arn" {
  description = "ARN of the auto-scaling policy"
  value       = aws_appautoscaling_policy.game_service_cpu.arn
}
