# GitLab + AWS CodePipeline Setup Guide

This guide walks you through setting up automated CI/CD from GitLab to AWS using CodePipeline.

---

## 📋 Prerequisites

- ✅ AWS Account with appropriate permissions
- ✅ GitLab account (GitLab.com or self-managed)
- ✅ Repository pushed to GitLab
- ✅ Terraform infrastructure deployed (VPCs, ECS, Lambda, etc.)

---

## 🔧 Step 1: Create GitLab Personal Access Token

### For GitLab.com:

1. **Go to GitLab Settings**
   - Navigate to: https://gitlab.com/-/profile/personal_access_tokens

2. **Create New Token**
   - Token name: `AWS CodePipeline`
   - Expiration: Set to at least 1 year (or your preference)
   - Scopes: Select **`api`** (full API access)
   
3. **Save the Token**
   - Copy the token immediately (you won't see it again!)
   - Store it securely (e.g., in AWS Secrets Manager or password manager)

### For GitLab Self-Managed:

1. **Go to your GitLab instance**
   - Navigate to: `https://your-gitlab-instance.com/-/profile/personal_access_tokens`

2. **Follow same steps as above**

---

## 🔗 Step 2: Create AWS CodeStar Connection to GitLab

### Option A: Using AWS Console (Recommended)

1. **Navigate to CodePipeline Settings**
   ```
   AWS Console → CodePipeline → Settings → Connections
   ```

2. **Create Connection**
   - Click **"Create connection"**
   - Provider: Select **"GitLab.com"** (or **"GitLab self-managed"**)
   - Connection name: `typerush-gitlab-connection`
   - Click **"Connect to GitLab"**

3. **Authorize Connection**
   - You'll be redirected to GitLab
   - Click **"Authorize"** to grant AWS access
   - You'll be redirected back to AWS

4. **Copy Connection ARN**
   - After creation, you'll see: `arn:aws:codestar-connections:REGION:ACCOUNT:connection/CONNECTION-ID`
   - **Copy this ARN** - you'll need it for Terraform!

### Option B: Using AWS CLI

```bash
# For GitLab.com
aws codestar-connections create-connection \
  --provider-type GitLab \
  --connection-name typerush-gitlab-connection

# Output will show: "ConnectionArn": "arn:aws:codestar-connections:..."

# IMPORTANT: Complete the connection in AWS Console
# The connection will be in PENDING status until you authorize it
# Go to: AWS Console → CodePipeline → Settings → Connections
# Click on the connection → "Update pending connection" → Authorize in GitLab
```

For **GitLab Self-Managed**, you need to create a host first:

```bash
# 1. Create host for GitLab self-managed
aws codestar-connections create-host \
  --name gitlab-self-managed-host \
  --provider-type GitLabSelfManaged \
  --provider-endpoint "https://gitlab.yourcompany.com"

# 2. Create connection using the host
aws codestar-connections create-connection \
  --provider-type GitLabSelfManaged \
  --connection-name typerush-gitlab-connection \
  --host-arn "arn:aws:codestar-connections:REGION:ACCOUNT:host/HOST-ID"

# 3. Complete setup in AWS Console as above
```

---

## 📝 Step 3: Update Terraform Configuration

Edit `infras/dev.auto.tfvars`:

```hcl
# CodePipeline Configuration (GitLab Integration)
codestar_connection_arn = "arn:aws:codestar-connections:ap-southeast-1:630633962130:connection/YOUR-CONNECTION-ID"
repository_id           = "hatohui/TypeRushService"  # Your GitLab username/repo
pipeline_branch_name    = "main"

# Enable pipelines
create_game_service_pipeline   = true
create_record_service_pipeline = true
create_text_service_pipeline   = true
create_frontend_pipeline       = true
```

**Important Notes:**
- Replace `YOUR-CONNECTION-ID` with your actual connection ID
- `repository_id` format: `username/repo-name` or `group/project-name`
- For GitLab groups, use the full path: `group/subgroup/project`

---

## 🚀 Step 4: Apply Terraform to Create Pipelines

```bash
cd infras

# Review changes
terraform plan

# Apply changes
terraform apply

# Confirm with 'yes'
```

This will create:
- ✅ 4 CodePipeline pipelines (Game, Record, Text, Frontend)
- ✅ 4 CodeBuild projects
- ✅ S3 bucket for artifacts
- ✅ All necessary IAM permissions

---

## 🔍 Step 5: Verify Pipelines

### Check Pipeline Status

```bash
# List all pipelines
aws codepipeline list-pipelines

# Check specific pipeline
aws codepipeline get-pipeline-state \
  --name typerush-dev-game-service
```

### View in AWS Console

```
AWS Console → CodePipeline → Pipelines

You should see:
- typerush-dev-game-service
- typerush-dev-record-service
- typerush-dev-text-service
- typerush-dev-frontend
```

---

## 🎯 Step 6: Trigger First Deployment

### Option 1: Automatic Trigger (Push to GitLab)

```bash
# Make any change to your code
git add .
git commit -m "Trigger pipeline"
git push origin main

# Pipeline will automatically start!
```

### Option 2: Manual Trigger

```bash
# Trigger specific pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-game-service

# Trigger all pipelines
for pipeline in game-service record-service text-service frontend; do
  aws codepipeline start-pipeline-execution \
    --name typerush-dev-$pipeline
done
```

---

## 📊 Step 7: Monitor Pipeline Execution

### Using AWS Console

```
AWS Console → CodePipeline → Select pipeline → View execution

You'll see:
1. Source stage (pulling from GitLab)
2. Build stage (CodeBuild compiling/building)
3. Deploy stage (deploying to ECS/Lambda/S3)
```

### Using AWS CLI

```bash
# Get latest execution
aws codepipeline get-pipeline-state \
  --name typerush-dev-game-service

# Watch CodeBuild logs
aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow

# Check ECS service after deployment
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service
```

---

## 🔐 Security Best Practices

### 1. Restrict GitLab Token Permissions

- ✅ Use token with minimum required scopes (`api` only)
- ✅ Set expiration date
- ✅ Rotate tokens regularly
- ✅ Revoke tokens when no longer needed

### 2. Secure CodeStar Connection

- ✅ Connection ARN is not a secret, but don't expose unnecessarily
- ✅ Use IAM policies to restrict who can use the connection
- ✅ Monitor connection usage in CloudTrail

### 3. Review IAM Permissions

```bash
# Check CodePipeline role permissions
aws iam get-role-policy \
  --role-name typerush-dev-codepipeline \
  --policy-name CodePipelinePolicy
```

---

## 🎛️ Pipeline Configuration Options

### Change Branch Name

Edit `dev.auto.tfvars`:
```hcl
pipeline_branch_name = "develop"  # or "staging", "production", etc.
```

Then apply:
```bash
cd infras && terraform apply
```

### Disable Specific Pipeline

```hcl
create_frontend_pipeline = false  # Disable frontend pipeline
```

### Configure Pipeline Triggers

By default, pipelines trigger on every push to the configured branch. To change:

1. **Manual Trigger Only**: In AWS Console, edit pipeline → Triggers → Disable automatic trigger

2. **Filter by File Paths**: Currently not supported via Terraform, but can be configured in AWS Console:
   - Edit pipeline → Source stage → Edit
   - Add file path filters (e.g., only trigger when `services/game-service/**` changes)

---

## 🐛 Troubleshooting

### Issue 1: Pipeline Fails at Source Stage

**Error**: "Could not access the repository"

**Solutions**:
1. Verify connection status: AWS Console → Connections → Check if "Available"
2. Re-authorize connection if needed
3. Check repository ID format (must be `owner/repo-name`)
4. Verify GitLab token hasn't expired

### Issue 2: Pipeline Fails at Build Stage

**Error**: "COMMAND_EXECUTION_ERROR"

**Solutions**:
1. Check CodeBuild logs:
   ```bash
   aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow
   ```
2. Verify `buildspec.yml` syntax
3. Check if all environment variables are set correctly
4. Ensure ECR repository exists

### Issue 3: Deploy Stage Fails (ECS)

**Error**: "Service update failed"

**Solutions**:
1. Check ECS task definition is valid
2. Verify security groups allow ECS tasks to run
3. Check ECR image was pushed successfully:
   ```bash
   aws ecr list-images --repository-name typerush/game-service
   ```

### Issue 4: Deploy Stage Fails (Lambda)

**Error**: "Function update failed"

**Solutions**:
1. Verify Lambda function exists
2. Check Lambda deployment package size (< 50MB zipped, < 250MB unzipped)
3. Review Lambda logs:
   ```bash
   aws logs tail /aws/lambda/typerush-dev-text-service
   ```

### Issue 5: GitLab Webhook Not Triggering Pipeline

**Symptoms**: Push to GitLab doesn't start pipeline

**Solutions**:
1. Check connection status (must be "Available")
2. Verify `DetectChanges: true` in pipeline configuration
3. Test manual trigger first:
   ```bash
   aws codepipeline start-pipeline-execution --name typerush-dev-game-service
   ```
4. Check if correct branch is configured

---

## 📈 Monitoring & Alerts

### Set Up CloudWatch Alarms for Pipeline Failures

```bash
# Create SNS topic for alerts
aws sns create-topic --name codepipeline-alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:ap-southeast-1:630633962130:codepipeline-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com

# Create CloudWatch alarm for pipeline failures
aws cloudwatch put-metric-alarm \
  --alarm-name pipeline-failures \
  --alarm-description "Alert on CodePipeline failures" \
  --metric-name PipelineExecutionFailure \
  --namespace AWS/CodePipeline \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions arn:aws:sns:ap-southeast-1:630633962130:codepipeline-alerts
```

---

## 🔄 Advanced: Multi-Branch Pipelines

To create separate pipelines for different branches (dev, staging, prod):

1. **Duplicate tfvars files**:
   ```bash
   cp dev.auto.tfvars staging.auto.tfvars
   cp dev.auto.tfvars prod.auto.tfvars
   ```

2. **Update branch names**:
   ```hcl
   # staging.auto.tfvars
   environment = "staging"
   pipeline_branch_name = "staging"
   
   # prod.auto.tfvars
   environment = "prod"
   pipeline_branch_name = "main"
   ```

3. **Deploy separate environments**:
   ```bash
   terraform workspace new staging
   terraform apply -var-file=staging.auto.tfvars
   
   terraform workspace new prod
   terraform apply -var-file=prod.auto.tfvars
   ```

---

## 📚 Additional Resources

- [AWS CodePipeline GitLab Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)
- [GitLab CI/CD with AWS](https://docs.gitlab.com/ee/ci/cloud_deployment/aws.html)
- [CodeBuild Buildspec Reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
- [Troubleshooting CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/troubleshooting.html)

---

## ✅ Quick Checklist

Use this checklist to ensure everything is set up:

- [ ] GitLab personal access token created (with `api` scope)
- [ ] CodeStar connection created and status is "Available"
- [ ] Connection ARN added to `dev.auto.tfvars`
- [ ] Repository ID correctly formatted in `dev.auto.tfvars`
- [ ] All pipeline flags set to `true` in `dev.auto.tfvars`
- [ ] Terraform applied successfully
- [ ] All 4 pipelines visible in AWS Console
- [ ] First pipeline execution triggered (manually or via push)
- [ ] Pipeline execution successful
- [ ] Services deployed and running
- [ ] CloudWatch logs showing no errors

---

## 🎉 Success!

Once everything is set up:
- ✅ Every push to GitLab automatically deploys to AWS
- ✅ Game Service builds Docker image and updates ECS
- ✅ Lambda functions automatically update
- ✅ Frontend deploys to S3 and invalidates CloudFront
- ✅ All deployments logged and monitored

**You now have a fully automated CI/CD pipeline! 🚀**
