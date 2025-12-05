# GitLab CodePipeline - Quick Start Guide

**5-Minute Setup** for automated CI/CD from GitLab to AWS

---

## 🚀 Quick Setup (3 Steps)

### 1️⃣ Create GitLab Token

Go to: https://gitlab.com/-/profile/personal_access_tokens

- Name: `AWS CodePipeline`
- Scope: ✅ **api**
- Expiration: 1 year
- Copy the token!

### 2️⃣ Create AWS Connection

**In AWS Console:**
```
CodePipeline → Settings → Connections → Create connection
→ Select "GitLab.com"
→ Name: "typerush-gitlab-connection"
→ Click "Connect to GitLab" → Authorize
→ Copy the Connection ARN
```

**Connection ARN looks like:**
```
arn:aws:codestar-connections:ap-southeast-1:123456789:connection/abc-123
```

### 3️⃣ Update Terraform & Deploy

Edit `infras/dev.auto.tfvars`:

```hcl
# Paste your connection ARN here
codestar_connection_arn = "arn:aws:codestar-connections:ap-southeast-1:630633962130:connection/YOUR-ID"

# Your GitLab username/repo
repository_id = "hatohui/TypeRushService"

# Already set to true
create_game_service_pipeline   = true
create_record_service_pipeline = true
create_text_service_pipeline   = true
create_frontend_pipeline       = true
```

Deploy:
```bash
cd infras
terraform apply
```

---

## ✅ Verify & Test

### Check Pipelines Created

```bash
aws codepipeline list-pipelines

# Should show:
# - typerush-dev-game-service
# - typerush-dev-record-service
# - typerush-dev-text-service
# - typerush-dev-frontend
```

### Trigger First Deployment

**Option 1: Push to GitLab (Automatic)**
```bash
git push origin main
# Pipeline triggers automatically!
```

**Option 2: Manual Trigger**
```bash
aws codepipeline start-pipeline-execution \
  --name typerush-dev-game-service
```

### Watch Deployment

**AWS Console:**
```
CodePipeline → Select pipeline → View execution
```

**CLI:**
```bash
# Watch build logs
aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow

# Check pipeline status
aws codepipeline get-pipeline-state --name typerush-dev-game-service
```

---

## 📋 What Happens When You Push?

```
git push origin main
    ↓
GitLab triggers CodePipeline
    ↓
Source Stage: Pull code from GitLab
    ↓
Build Stage: CodeBuild runs buildspec.yml
    ↓
Deploy Stage:
    • Game Service → Docker image → ECR → ECS update
    • Record/Text Services → Lambda package → Lambda update  
    • Frontend → Build → S3 sync → CloudFront invalidate
    ↓
✅ Deployment Complete!
```

---

## 🎯 Buildspec Files (Already Created)

All buildspec files are ready in your repo:

- ✅ `services/game-service/buildspec.yml` - Docker build & ECR push
- ✅ `services/record-service/buildspec.yml` - Node.js Lambda build
- ✅ `services/text-service/buildspec.yml` - Python Lambda build
- ✅ `frontend/buildspec.yml` - React/Vite build & S3 deploy

No changes needed - they're configured to work automatically!

---

## 🐛 Troubleshooting

### Pipeline Fails at Source Stage

```bash
# Check connection status
aws codestar-connections get-connection \
  --connection-arn YOUR-ARN

# Status should be: "AVAILABLE"
# If "PENDING", re-authorize in AWS Console
```

### Build Fails

```bash
# Check logs
aws logs tail /aws/codebuild/typerush-dev-SERVICE-build --follow

# Common issues:
# - Missing environment variables (check CodeBuild project)
# - Syntax error in buildspec.yml
# - Missing dependencies
```

### Deploy Fails

```bash
# For ECS (Game Service)
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service

# For Lambda
aws lambda get-function \
  --function-name typerush-dev-text-service
```

---

## 📚 Full Documentation

For detailed setup, troubleshooting, and advanced configs:
- 📖 `docs/GITLAB_CODEPIPELINE_SETUP.md` - Complete guide
- 📖 `VERIFICATION_AND_DEPLOYMENT_GUIDE.md` - Testing & verification
- 📖 `QUICK_DEPLOY.md` - Deployment options

---

## 🎉 That's It!

You now have:
- ✅ Automated deployments on every push
- ✅ Game Service auto-deploys to ECS
- ✅ Lambda functions auto-update
- ✅ Frontend auto-deploys to S3/CloudFront
- ✅ Build logs in CloudWatch
- ✅ Pipeline monitoring in AWS Console

**Push to GitLab and watch it deploy! 🚀**

---

## Quick Reference Commands

```bash
# Trigger all pipelines
for p in game-service record-service text-service frontend; do
  aws codepipeline start-pipeline-execution --name typerush-dev-$p
done

# Watch all build logs
aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow

# Check all pipeline statuses
aws codepipeline list-pipeline-executions --pipeline-name typerush-dev-game-service

# View in browser
open https://console.aws.amazon.com/codesuite/codepipeline/pipelines
```
