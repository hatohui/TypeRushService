# Step 10: ECR Repositories

## Status: IMPLEMENTED (Not Applied)

**Implemented on**: November 23, 2025  
**Applied to AWS**: Not yet - waiting for full stack implementation

**Note**: This module has been coded and validated in Terraform but NOT yet applied to AWS infrastructure. We're implementing all modules first, then will apply the complete infrastructure stack together to ensure proper dependency management.

## Terraform Module: `modules/10-ecr`

## Overview

Create Amazon Elastic Container Registry (ECR) repositories to store Docker images for Game Service and Record Service. Includes lifecycle policies for automatic image cleanup.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: Store Docker images for ECS and Lambda
- **Repositories**: 2 (game-service, record-service)
- **Cost**: $0.10/GB/month storage + minimal data transfer
- **Access**: CodeBuild pushes, ECS/Lambda pull via VPC endpoints

## Components to Implement

### 1. Game Service ECR Repository

- [x] **Repository Name**: `typerush/game-service`
- [x] **Image Tag Mutability**: MUTABLE (allow tag overwrites in dev)
- [x] **Image Scanning**: Enabled on push
- [x] **Encryption**: AES256 (AWS-managed)
- [x] **Lifecycle Policy**: Keep last 10 images, expire untagged after 7 days

### 2. Record Service ECR Repository

- [x] **Repository Name**: `typerush/record-service`
- [x] **Image Tag Mutability**: MUTABLE
- [x] **Image Scanning**: Enabled on push
- [x] **Encryption**: AES256
- [x] **Lifecycle Policy**: Keep last 10 images, expire untagged after 7 days

### 3. Repository Policies

- [x] **CodeBuild**: Allow push (BatchCheckLayerAvailability, PutImage, InitiateLayerUpload, etc.)
- [x] **ECS Task Execution**: Allow pull (GetDownloadUrlForLayer, BatchGetImage, BatchCheckLayerAvailability)
- [x] **Cross-Account**: None (single account setup)

### 4. Lifecycle Policies

#### Rule 1: Expire Untagged Images

- [x] **Priority**: 1
- [x] **Description**: "Expire untagged images older than 7 days"
- [x] **Selection**:
  - Tag Status: untagged
  - Count Type: sinceImagePushed
  - Count Unit: days
  - Count Number: 7
- [x] **Action**: expire

#### Rule 2: Keep Last 10 Tagged Images

- [x] **Priority**: 2
- [x] **Description**: "Keep last 10 tagged images"
- [x] **Selection**:
  - Tag Status: tagged
  - Tag Prefix List: ["v", "prod", "staging", "dev", "latest"]
  - Count Type: imageCountMoreThan
  - Count Number: 10
- [x] **Action**: expire

### 5. Image Scanning Configuration

- [x] **Scan On Push**: True
- [x] **Scan Frequency**: On push only (not continuous)
- [x] **Scan Findings**: View in ECR console or via API
- [x] **Purpose**: Detect vulnerabilities (CVEs) in base images

## Implementation Details

### Terraform Configuration

```hcl
# Game Service Repository
resource "aws_ecr_repository" "game_service" {
  name                 = "${var.project_name}/game-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-game-service-ecr"
      Service = "game-service"
    }
  )
}

# Lifecycle Policy for Game Service
resource "aws_ecr_lifecycle_policy" "game_service" {
  repository = aws_ecr_repository.game_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "prod", "staging", "dev"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Record Service Repository (similar structure)
resource "aws_ecr_repository" "record_service" {
  name                 = "${var.project_name}/record-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-record-service-ecr"
      Service = "record-service"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "record_service" {
  repository = aws_ecr_repository.record_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "prod", "staging", "dev"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

## Module Structure

```
modules/09-ecr/
├── main.tf       # ECR repositories and lifecycle policies
├── variables.tf  # Project name, environment
└── outputs.tf    # Repository URLs, ARNs
```

## Dependencies

- **Required**: None (ECR is independent)
- **Used By**: Module 18 (CodeBuild) pushes images, Module 10 (ECS) pulls images

## Deployment

```powershell
# Deploy ECR repositories (takes ~30 seconds)
terraform apply -var-file="env\dev.tfvars.local" -target=module.ecr
```

## Validation Commands

```powershell
# List repositories
aws ecr describe-repositories

# Get repository URI
$GAME_SERVICE_REPO = terraform output -raw game_service_repository_url
$RECORD_SERVICE_REPO = terraform output -raw record_service_repository_url

echo "Game Service: $GAME_SERVICE_REPO"
echo "Record Service: $RECORD_SERVICE_REPO"

# Get lifecycle policy
aws ecr get-lifecycle-policy --repository-name typerush/game-service

# Describe image scan findings (after pushing image)
aws ecr describe-image-scan-findings `
  --repository-name typerush/game-service `
  --image-id imageTag=latest
```

## Building and Pushing Images

### Game Service (Node.js)

```powershell
# Navigate to Game Service directory
cd services\game-service

# Build Docker image
docker build -t typerush/game-service:latest .

# Get ECR login token
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $GAME_SERVICE_REPO

# Tag image
docker tag typerush/game-service:latest $GAME_SERVICE_REPO:latest
docker tag typerush/game-service:latest $GAME_SERVICE_REPO:v1.0.0

# Push image
docker push $GAME_SERVICE_REPO:latest
docker push $GAME_SERVICE_REPO:v1.0.0
```

### Record Service (NestJS)

```powershell
# Navigate to Record Service directory
cd services\record-service

# Build Docker image
docker build -t typerush/record-service:latest .

# Get ECR login token
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $RECORD_SERVICE_REPO

# Tag image
docker tag typerush/record-service:latest $RECORD_SERVICE_REPO:latest
docker tag typerush/record-service:latest $RECORD_SERVICE_REPO:v1.0.0

# Push image
docker push $RECORD_SERVICE_REPO:latest
docker push $RECORD_SERVICE_REPO:v1.0.0
```

### Automated via CodeBuild (Preferred)

```yaml
# buildspec.yml for Game Service
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Building Docker image...
      - docker build -t $ECR_REPO_URI:latest .
      - docker tag $ECR_REPO_URI:latest $ECR_REPO_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Pushing Docker image...
      - docker push $ECR_REPO_URI:latest
      - docker push $ECR_REPO_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"game-service","imageUri":"%s"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

## Cost Impact

**$0.50-1.00/month** (estimated for dev)

### Pricing Breakdown

- **Storage**: $0.10 per GB-month
  - Game Service: ~500 MB × 10 images = 5 GB = $0.50
  - Record Service: ~300 MB × 10 images = 3 GB = $0.30
- **Data Transfer**:
  - Push from CodeBuild: FREE (same region)
  - Pull to ECS via VPC endpoint: FREE (private)
  - Pull to Lambda: FREE (same region)
- **Image Scanning**: FREE (first 1,000 scans/month)

**Total**: ~$0.80/month
**4-day demo**: ~$0.11

## Image Tagging Strategy

### Development

```
<repo>:latest           # Always points to most recent dev build
<repo>:dev-<git-sha>    # Dev builds (short SHA)
<repo>:dev-<timestamp>  # Dev builds by time
```

### Staging

```
<repo>:staging          # Staging environment
<repo>:staging-<git-sha>
```

### Production

```
<repo>:prod             # Current production
<repo>:v1.0.0           # Semantic versioning
<repo>:prod-<git-sha>   # Production builds
```

## Security Considerations

### ✅ Image Scanning

- Scan on every push
- Review findings before deployment
- Set threshold: block deployment if CRITICAL vulnerabilities found

### ✅ Access Control

- **CodeBuild IAM Role**: Push permissions only
- **ECS Task Execution Role**: Pull permissions only
- **No public access**: Repositories are private

### ✅ Encryption

- All images encrypted at rest (AES256)
- All data transfer uses TLS

### ✅ VPC Endpoint Usage

```
CodeBuild (in VPC) → ECR API VPC Endpoint → Push image
CodeBuild (in VPC) → ECR Docker VPC Endpoint → Push layers
ECS Task (private subnet) → ECR API VPC Endpoint → Get manifest
ECS Task (private subnet) → ECR Docker VPC Endpoint → Pull layers
```

## Monitoring and Alerting

### CloudWatch Metrics (Custom)

- [ ] Monitor image push frequency
- [ ] Track repository size growth
- [ ] Alert on scan findings

### Cost Anomaly Detection

- [ ] Set up AWS Cost Anomaly Detection for ECR
- [ ] Alert if monthly cost > $5 (unusual for dev)

## Image Size Optimization

### Best Practices

1. **Multi-stage builds**: Separate build and runtime stages

   ```dockerfile
   # Build stage
   FROM node:20-alpine AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   # Runtime stage
   FROM node:20-alpine
   WORKDIR /app
   COPY --from=builder /app/dist ./dist
   COPY --from=builder /app/node_modules ./node_modules
   CMD ["node", "dist/main.js"]
   ```

2. **Use Alpine base images**: Reduce size by 80%
3. **Leverage layer caching**: COPY package.json before source code
4. **Remove dev dependencies**: Use `npm ci --production`
5. **.dockerignore**: Exclude node_modules, .git, tests

### Expected Image Sizes

- Game Service: 100-150 MB (Node.js + Express)
- Record Service: 120-180 MB (NestJS + Prisma)
- Text Service: 800-1000 MB (Python + ML dependencies - not in ECR, Lambda deployment package)

## Testing Plan

1. [ ] Deploy ECR repositories
2. [ ] Verify repositories are created
3. [ ] Build Game Service Docker image locally
4. [ ] Push Game Service image to ECR
5. [ ] Verify image appears in ECR console
6. [ ] Check image scan results
7. [ ] Build Record Service Docker image
8. [ ] Push Record Service image to ECR
9. [ ] Verify lifecycle policy applies (simulate old images)
10. [ ] Test ECS can pull image via VPC endpoint

## Common Issues

### Issue: Authentication failure

```
Error: no basic auth credentials
Solution: Run aws ecr get-login-password | docker login ...
Token expires after 12 hours, re-authenticate if needed
```

### Issue: Image scan fails

```
Error: Image scan failed with status FAILED
Solution: Wait 1 minute and trigger manual scan via console
AWS may have temporary issues
```

### Issue: Lifecycle policy not working

```
Issue: Old images not deleted
Solution: Lifecycle policies run once every 24 hours
Wait or trigger manual evaluation via console
```

## Rollback Plan

```powershell
# Export image tags before deletion
aws ecr list-images --repository-name typerush/game-service > game-service-images.json
aws ecr list-images --repository-name typerush/record-service > record-service-images.json

# Destroy ECR repositories
terraform destroy -target=module.ecr

# Note: Images are PERMANENTLY deleted when repository is deleted
# Ensure you have backups or can rebuild from source
```

## Next Step

Proceed to [Step 11: ECS Cluster and Game Service](./11_ecs_cluster.md)
