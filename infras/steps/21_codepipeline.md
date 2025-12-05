# Step 21: CodePipeline CI/CD

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/26-codepipeline`

## Overview

Create AWS CodePipeline for automated CI/CD, orchestrating builds, migrations, and deployments triggered by GitLab webhooks.

## Architecture Reference

From `architecture-diagram.md`:

- **Trigger**: GitLab webhook on push to main branch
- **Stages**: Source → Build → Migrate → Deploy
- **Services**: Game, Record, Text services + Frontend
- **Cost**: $1/active pipeline/month + CodeBuild costs

## Components to Implement

### 1. Game Service Pipeline

**Stages**:

1. Source: GitLab repository
2. Build: CodeBuild (build + push ECR image)
3. Deploy: ECS service update

### 2. Record Service Pipeline

**Stages**:

1. Source: GitLab repository
2. Build: CodeBuild (build Lambda package)
3. Migrate: CodeBuild (run Prisma migrations)
4. Deploy: Lambda function update

### 3. Text Service Pipeline

**Stages**:

1. Source: GitLab repository
2. Build: CodeBuild (build Lambda package)
3. Deploy: Lambda function update

### 4. Frontend Pipeline

**Stages**:

1. Source: GitLab repository (frontend folder)
2. Build: CodeBuild (npm build)
3. Deploy: S3 upload + CloudFront invalidation

## Implementation Details

### Terraform Configuration

```hcl
# Game Service Pipeline
resource "aws_codepipeline" "game_service" {
  name     = "${var.project_name}-game-service-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = var.artifacts_bucket_name
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitLab"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.gitlab_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = "main"
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.game_service.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.game_service_name
        FileName    = "imageDetail.json"
      }
    }
  }

  tags = var.tags
}

# Record Service Pipeline (with migration stage)
resource "aws_codepipeline" "record_service" {
  name     = "${var.project_name}-record-service-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = var.artifacts_bucket_name
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitLab"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.gitlab_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.record_service.name
      }
    }
  }

  stage {
    name = "Migrate"
    action {
      name            = "MigrateAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.record_service_migrate.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        FunctionName = var.record_service_lambda_name
      }
    }
  }

  tags = var.tags
}

output "game_service_pipeline_name" {
  value = aws_codepipeline.game_service.name
}

output "record_service_pipeline_name" {
  value = aws_codepipeline.record_service.name
}
```

## Deployment Steps

```powershell
terraform apply -target=module.codepipeline -var-file="env/dev.tfvars.local"

# Configure GitLab webhook
# GitLab Repository → Settings → Webhooks
# URL: AWS CodePipeline webhook URL
# Trigger: Push events to main branch
```

## Cost Estimation

- **Pipelines**: $1/active pipeline × 4 = $4/month
- **CodeBuild**: Included in Step 20 costs
- **Total**: **$4/month**

## References

- [CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [GitLab Integration](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)
