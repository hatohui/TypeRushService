# ========================================
# ECS Cluster and Game Service
# ========================================

data "aws_region" "current" {}

# ========================================
# ECS Cluster
# ========================================

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Disabled for dev to save costs
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-cluster"
    }
  )
}

# ========================================
# CloudWatch Log Group
# ========================================

resource "aws_cloudwatch_log_group" "game_service" {
  name              = "/ecs/${var.project_name}-${var.environment}-game-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-logs"
      Service = "game-service"
    }
  )
}

# ========================================
# ECS Task Definition
# ========================================

resource "aws_ecs_task_definition" "game_service" {
  family                   = "${var.project_name}-${var.environment}-game-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.game_service_cpu
  memory                   = var.game_service_memory
  task_role_arn            = var.game_service_task_role_arn
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "game-service"
      image     = "${var.game_service_ecr_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "LOG_LEVEL"
          value = "info"
        },
        {
          name  = "REDIS_ENDPOINT"
          value = var.redis_endpoint
        }
      ]

      secrets = [
        {
          name      = "REDIS_AUTH_TOKEN"
          valueFrom = "${var.redis_secret_arn}:auth_token::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.game_service.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-task"
      Service = "game-service"
    }
  )
}

# ========================================
# ECS Service
# ========================================

resource "aws_ecs_service" "game_service" {
  name             = "${var.project_name}-${var.environment}-game-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.game_service.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.game_service_target_group_arn
    container_name   = "game-service"
    container_port   = 3000
  }

  health_check_grace_period_seconds = 60

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  depends_on = [var.alb_listener_arn]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service"
      Service = "game-service"
    }
  )
}

# ========================================
# Auto Scaling
# ========================================

resource "aws_appautoscaling_target" "game_service" {
  max_capacity       = var.game_service_max_capacity
  min_capacity       = var.game_service_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.game_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "game_service_cpu" {
  name               = "${var.project_name}-${var.environment}-game-service-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.game_service.resource_id
  scalable_dimension = aws_appautoscaling_target.game_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.game_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.game_service_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
