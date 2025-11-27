# Step 20: CodeBuild Projects

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/19-codebuild`

## Overview

Create AWS CodeBuild projects for building Docker images, running database migrations, and deploying services.

## Architecture Reference

From `architecture-diagram.md`:

- **Build Project**: Build and push Docker images to ECR
- **Migrate Project**: Run Prisma database migrations for Record Service
- **Deploy**: Triggered by CodePipeline from GitLab webhook
- **Cost**: $0.005/build minute (t2.small), ~$2-5/month

## Components to Implement

### 1. Game Service Build Project

- [ ] **Project Name**: `typerush-dev-game-service-build`
- [ ] **Source**: GitLab repository
- [ ] **Environment**:
  - Image: aws/codebuild/standard:7.0
  - Compute: BUILD_GENERAL1_SMALL
  - Privileged: true (Docker build)
- [ ] **Buildspec**: `services/game-service/buildspec.yml`

### 2. Record Service Build Project

- [ ] **Project Name**: `typerush-dev-record-service-build`
- [ ] **Source**: GitLab repository
- [ ] **Environment**: Same as Game Service
- [ ] **Buildspec**: `services/record-service/buildspec.yml`

### 3. Record Service Migration Project

- [ ] **Project Name**: `typerush-dev-record-service-migrate`
- [ ] **Source**: GitLab repository
- [ ] **Environment**: Standard Node.js 20
- [ ] **Buildspec**: `services/record-service/buildspec-migrate.yml`
- [ ] **Purpose**: Run `npx prisma migrate deploy`

### 4. Text Service Build Project

- [ ] **Project Name**: `typerush-dev-text-service-build`
- [ ] **Source**: GitLab repository
- [ ] **Environment**: Python 3.12
- [ ] **Buildspec**: `services/text-service/buildspec.yml`

### 5. Frontend Build Project

- [ ] **Project Name**: `typerush-dev-frontend-build`
- [ ] **Source**: GitLab repository
- [ ] **Environment**: Standard Node.js 20
- [ ] **Buildspec**: `frontend/buildspec.yml`
- [ ] **Artifacts**: Upload to S3 bucket

## Implementation Details

### Terraform Configuration

```hcl
# Game Service Build Project
resource "aws_codebuild_project" "game_service" {
  name          = "${var.project_name}-game-service-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 30

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.game_service_ecr_uri
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  source {
    type      = "GITLAB"
    location  = var.gitlab_repository_url
    buildspec = "services/game-service/buildspec.yml"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = [var.codebuild_security_group_id]
  }

  tags = var.tags
}

# Record Service Migration Project
resource "aws_codebuild_project" "record_service_migrate" {
  name          = "${var.project_name}-record-service-migrate"
  service_role  = var.codebuild_role_arn
  build_timeout = 10

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DB_SECRET_ARN"
      value = var.rds_secret_arn
    }

    environment_variable {
      name  = "RDS_ENDPOINT"
      value = var.rds_endpoint
    }
  }

  source {
    type      = "GITLAB"
    location  = var.gitlab_repository_url
    buildspec = "services/record-service/buildspec-migrate.yml"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = [var.codebuild_security_group_id]
  }

  tags = var.tags
}
```

### Sample Buildspec (services/game-service/buildspec.yml)

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}

  build:
    commands:
      - echo Build started on `date`
      - echo Building Docker image...
      - cd services/game-service
      - docker build -t $ECR_REPOSITORY_URI:latest .
      - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$IMAGE_TAG

  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing Docker images...
      - docker push $ECR_REPOSITORY_URI:latest
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - printf '{"ImageURI":"%s"}' $ECR_REPOSITORY_URI:$IMAGE_TAG > imageDetail.json

artifacts:
  files:
    - imageDetail.json
```

## Deployment Steps

```powershell
terraform apply -target=module.codebuild -var-file="env/dev.tfvars.local"

# Trigger manual build for testing
aws codebuild start-build --project-name typerush-dev-game-service-build
```

## Cost Estimation

- **Small Instance**: $0.005/minute
- **Average Build**: 5 minutes
- **Builds per Month**: 50
- **Total**: 50 × 5 × $0.005 = **$1.25/month**

## References

- [CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [Buildspec Reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
