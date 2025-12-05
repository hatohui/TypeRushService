# Step 11: ECS Cluster and Game Service

## Status: IMPLEMENTED (Not Applied)

**Implemented on**: November 23, 2025  
**Applied to AWS**: Not yet - waiting for full stack implementation

**Note**: This module has been coded and will be validated after ALB module (Step 13) is implemented. All modules will be applied together.

## Terraform Module: `modules/11-ecs`

## Overview

Create an ECS Fargate cluster and deploy the Game Service as a containerized application with auto-scaling, load balancing, and health checks.

## Architecture Reference

From `architecture-diagram.md`:

- **Cluster**: ECS Fargate (serverless, no EC2 instances)
- **Service**: Game Service (Node.js + Express)
- **Compute**: 0.25 vCPU, 0.5 GB RAM per task
- **Auto-scaling**: Min 1, Max 2 tasks (CPU-based)
- **Cost**: $10.88/month (1 task always running)
- **Network**: Private subnet, accessed via internal ALB

## Components to Implement

### 1. ECS Cluster

- [ ] **Cluster Name**: `typerush-dev-ecs-cluster`
- [ ] **Capacity Providers**: FARGATE, FARGATE_SPOT (optional)
- [ ] **Container Insights**: Disabled (dev, save costs)
- [ ] **Default Capacity Provider Strategy**: FARGATE 100%

### 2. CloudWatch Log Group

- [ ] **Log Group**: `/ecs/typerush-dev-game-service`
- [ ] **Retention**: 7 days
- [ ] **Encryption**: Default (CloudWatch encryption)

### 3. Task Definition

- [ ] **Family**: `typerush-dev-game-service`
- [ ] **Network Mode**: awsvpc (required for Fargate)
- [ ] **Requires Compatibilities**: FARGATE
- [ ] **CPU**: 256 (.25 vCPU)
- [ ] **Memory**: 512 (0.5 GB)
- [ ] **Task Role**: Game Service Task Role (from Module 03)
- [ ] **Execution Role**: ECS Task Execution Role (from Module 03)

### 4. Container Definition

- [ ] **Container Name**: `game-service`
- [ ] **Image**: ECR repository URI (from Module 09)
- [ ] **Essential**: true
- [ ] **Port Mappings**: 3000 (HTTP)
- [ ] **Environment Variables**:
  - `NODE_ENV`: production
  - `PORT`: 3000
  - `LOG_LEVEL`: info
- [ ] **Secrets** (from Secrets Manager):
  - `REDIS_AUTH_TOKEN`: typerush/elasticache/auth-token
  - `REDIS_ENDPOINT`: (injected via env var, not secret)
- [ ] **Health Check**:
  - Command: `["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]`
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Retries: 3
  - Start Period: 60 seconds
- [ ] **Logging**:
  - Driver: awslogs
  - Options:
    - awslogs-group: /ecs/typerush-dev-game-service
    - awslogs-region: ap-southeast-1
    - awslogs-stream-prefix: ecs

### 5. ECS Service

- [ ] **Service Name**: `typerush-dev-game-service`
- [ ] **Cluster**: typerush-dev-ecs-cluster
- [ ] **Task Definition**: Latest revision
- [ ] **Desired Count**: 1
- [ ] **Launch Type**: FARGATE
- [ ] **Platform Version**: LATEST
- [ ] **Network Configuration**:
  - Subnets: Private subnet
  - Security Groups: ECS security group
  - Assign Public IP: DISABLED
- [ ] **Load Balancer**:
  - Target Group: Game Service target group (from Module 12)
  - Container Name: game-service
  - Container Port: 3000
- [ ] **Health Check Grace Period**: 60 seconds
- [ ] **Deployment Configuration**:
  - Deployment Type: ROLLING_UPDATE
  - Maximum Percent: 200
  - Minimum Healthy Percent: 100
- [ ] **Enable ECS Exec**: true (for debugging)

### 6. Auto Scaling

- [ ] **Auto Scaling Target**:
  - Service: typerush-dev-game-service
  - Min Capacity: 1
  - Max Capacity: 2
  - Scalable Dimension: ecs:service:DesiredCount
- [ ] **Auto Scaling Policy** (Target Tracking):
  - Policy Name: `cpu-target-tracking`
  - Policy Type: TargetTrackingScaling
  - Target Value: 70% CPU
  - Scale-In Cooldown: 300 seconds
  - Scale-Out Cooldown: 60 seconds

## Implementation Details

### Terraform Configuration

```hcl
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-cluster"
    }
  )
}

# CloudWatch Log Group
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

# Task Definition
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
          "awslogs-region"        = data.aws_region.current.name
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

# ECS Service
resource "aws_ecs_service" "game_service" {
  name            = "${var.project_name}-${var.environment}-game-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.game_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"
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

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
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

# Auto Scaling Target
resource "aws_appautoscaling_target" "game_service" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.game_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy
resource "aws_appautoscaling_policy" "game_service_cpu" {
  name               = "${var.project_name}-${var.environment}-game-service-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.game_service.resource_id
  scalable_dimension = aws_appautoscaling_target.game_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.game_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

## Module Structure

```
modules/10-ecs/
├── main.tf       # Cluster, task definition, service, auto-scaling
├── variables.tf  # CPU, memory, ECR URL, subnet IDs, role ARNs
└── outputs.tf    # Cluster ID, service name, task definition ARN
```

## Dependencies

- **Required**: Module 01 (Networking) - Private subnet
- **Required**: Module 02 (Security Groups) - ECS security group
- **Required**: Module 03 (IAM) - Task and execution roles
- **Required**: Module 07 (ElastiCache) - Redis endpoint
- **Required**: Module 09 (ECR) - Container image
- **Required**: Module 12 (ALB) - Target group and listener

## Deployment

```powershell
# Deploy ECS cluster and service (takes ~5-10 minutes)
terraform apply -var-file="env\dev.tfvars.local" -target=module.ecs
```

## Validation Commands

```powershell
# List clusters
aws ecs list-clusters

# Describe cluster
aws ecs describe-clusters --clusters typerush-dev-ecs-cluster

# List services
aws ecs list-services --cluster typerush-dev-ecs-cluster

# Describe service
aws ecs describe-services --cluster typerush-dev-ecs-cluster `
  --services typerush-dev-game-service

# List tasks
aws ecs list-tasks --cluster typerush-dev-ecs-cluster `
  --service-name typerush-dev-game-service

# Get task details
$TASK_ARN = (aws ecs list-tasks --cluster typerush-dev-ecs-cluster `
  --service-name typerush-dev-game-service --query 'taskArns[0]' --output text)

aws ecs describe-tasks --cluster typerush-dev-ecs-cluster --tasks $TASK_ARN

# View logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Execute command in container (debugging)
aws ecs execute-command --cluster typerush-dev-ecs-cluster `
  --task $TASK_ARN --container game-service `
  --command "/bin/sh" --interactive
```

## Cost Impact

**$10.88/month** (1 task always running)

### Fargate Pricing Breakdown

- **vCPU**: 0.25 vCPU × $0.04656/vCPU/hour = $0.01164/hour
- **Memory**: 0.5 GB × $0.00511/GB/hour = $0.002555/hour
- **Total per task**: $0.014195/hour = $10.22/month
- **With auto-scaling (avg 1.1 tasks)**: ~$11.24/month

**4-day demo**: $0.34/day × 4 = $1.36

### Cost Optimization

```
Current (0.25 vCPU, 0.5 GB): $10.22/mo
Minimum (0.25 vCPU, 0.5 GB): Same (already minimal)
Fargate Spot (70% discount): $3.07/mo (but may be interrupted)
```

## Testing Plan

1. [ ] Deploy ECS cluster
2. [ ] Deploy task definition
3. [ ] Deploy ECS service
4. [ ] Verify task starts successfully
5. [ ] Check task logs in CloudWatch
6. [ ] Test health check endpoint
7. [ ] Verify service registers with ALB target group
8. [ ] Test auto-scaling by increasing CPU load
9. [ ] Test ECS Exec (debug access)
10. [ ] Test rolling deployment (update task definition)

## Debugging

### View Container Logs

```powershell
# Get task ID
$TASK_ID = (aws ecs list-tasks --cluster typerush-dev-ecs-cluster `
  --service-name typerush-dev-game-service --query 'taskArns[0]' --output text).Split('/')[-1]

# View logs
aws logs get-log-events --log-group-name /ecs/typerush-dev-game-service `
  --log-stream-name "ecs/game-service/$TASK_ID" --limit 50
```

### Access Container Shell

```powershell
# Enable ECS Exec (already enabled in service config)
# Execute interactive shell
aws ecs execute-command --cluster typerush-dev-ecs-cluster `
  --task $TASK_ARN --container game-service `
  --command "/bin/sh" --interactive
```

### Check Task Metadata

```powershell
# Inside container, query ECS task metadata endpoint
curl http://169.254.170.2/v2/metadata
```

## Common Issues

### Issue: Task fails to start

```
Error: CannotPullContainerError
Solution:
- Verify ECR repository exists and has image
- Check ECS Task Execution Role has ECR permissions
- Verify VPC endpoints for ECR API and Docker
```

### Issue: Health check failing

```
Error: Service is unhealthy in target group
Solution:
- Check /health endpoint returns 200 OK
- Verify security group allows ALB → ECS on port 3000
- Increase health check grace period if app takes time to start
```

### Issue: Cannot retrieve secrets

```
Error: ResourceInitializationError: unable to pull secrets
Solution:
- Verify Secrets Manager VPC endpoint exists
- Check Task Execution Role has secretsmanager:GetSecretValue
- Verify secret ARN is correct in task definition
```

## Monitoring and Alerting

### CloudWatch Metrics

- [ ] CPUUtilization > 80% for 5 minutes
- [ ] MemoryUtilization > 90% for 5 minutes
- [ ] TargetResponseTime > 1000ms (from ALB)
- [ ] UnhealthyHostCount > 0 (target group)
- [ ] DesiredTaskCount != RunningTaskCount (service instability)

### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-game-service-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Game Service CPU utilization is too high"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.game_service.name
  }
}
```

## Deployment Strategies

### Blue/Green Deployment (Future)

- Use CodeDeploy with ECS
- Create new task set with updated image
- Shift traffic gradually (10%, 50%, 100%)
- Automatic rollback on health check failures

### Rolling Update (Current)

- Update task definition with new image tag
- ECS starts new tasks with new image
- Waits for health checks to pass
- Drains and stops old tasks
- **Downtime**: None (if minimum_healthy_percent = 100)

## Rollback Plan

```powershell
# List task definition revisions
aws ecs list-task-definitions --family-prefix typerush-dev-game-service

# Update service to previous revision
aws ecs update-service --cluster typerush-dev-ecs-cluster `
  --service typerush-dev-game-service `
  --task-definition typerush-dev-game-service:1

# Destroy ECS resources
terraform destroy -target=module.ecs
```

## Next Step

Proceed to [Step 12: Lambda Functions](./12_lambda_functions.md)
