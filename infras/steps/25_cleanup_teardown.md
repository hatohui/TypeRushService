# Step 25: Cleanup and Teardown

## Status: NOT STARTED

## Terraform Module: N/A (destroys all modules)

## Overview

**IMPORTANT**: This is a learning project. To avoid ongoing AWS costs (~$105-120/month), destroy all infrastructure after you're done learning. This guide provides safe teardown procedures.

## Cost Reminder

### Running Costs (per day)

- **4 days**: ~$16
- **1 week**: ~$28
- **1 month**: ~$105-120

### What Continues to Charge

- NAT Gateway: **$1.10/day** ($32.40/month)
- VPC Endpoints: **$0.96/day** ($28.80/month)
- RDS: **$0.48/day** ($14.40/month)
- ElastiCache: **$0.41/day** ($12.41/month)
- ALB: **$0.54/day** ($16.20/month)
- ECS Fargate (1 task): **$0.36/day** ($10.88/month)

## Pre-Teardown Checklist

### 1. Backup Important Data (Optional)

#### RDS Database Snapshot

```powershell
# Create manual snapshot before destroying
aws rds create-db-snapshot `
  --db-instance-identifier typerush-dev-rds `
  --db-snapshot-identifier typerush-dev-final-snapshot-$(Get-Date -Format "yyyyMMdd")

# Snapshot cost: ~$0.10/GB/month (much cheaper than running instance)
```

#### DynamoDB Backup

```powershell
# Export DynamoDB table to S3 (optional)
aws dynamodb export-table-to-point-in-time `
  --table-arn <table-arn> `
  --s3-bucket typerush-dev-frontend `
  --s3-prefix dynamodb-backup/ `
  --export-format DYNAMODB_JSON
```

#### ECR Images Backup

```powershell
# Pull Docker images locally (if needed)
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

docker pull <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/typerush/game-service:latest
docker save <image-id> -o game-service-backup.tar
```

### 2. Document Configuration

```powershell
# Export current Terraform state for reference
terraform show > terraform-state-backup.txt

# Export all resource IDs
terraform output -json > terraform-outputs-backup.json

# List all resources
terraform state list > terraform-resources-backup.txt
```

### 3. Download Application Logs (Optional)

```powershell
# Export ECS logs
aws logs create-export-task `
  --log-group-name /ecs/typerush-dev-game-service `
  --from (Get-Date).AddDays(-7).ToUniversalTime() `
  --to (Get-Date).ToUniversalTime() `
  --destination typerush-dev-frontend `
  --destination-prefix logs/ecs/

# Export Lambda logs
aws logs create-export-task `
  --log-group-name /aws/lambda/typerush-dev-record-service `
  --from (Get-Date).AddDays(-7).ToUniversalTime() `
  --to (Get-Date).ToUniversalTime() `
  --destination typerush-dev-frontend `
  --destination-prefix logs/lambda/
```

## Teardown Procedure

### Step 1: Review What Will Be Destroyed

```powershell
cd d:\Repository\TypeRushService\infras

# Preview destruction (IMPORTANT - review carefully)
terraform plan -destroy -var-file="env/dev.tfvars.local" | Out-File -FilePath destroy-plan.txt

# Review the plan
cat destroy-plan.txt

# Count resources to be destroyed
terraform state list | Measure-Object -Line
```

### Step 2: Destroy Infrastructure (Recommended Order)

#### Option A: Destroy Everything at Once

```powershell
# This destroys ALL resources in one command
terraform destroy -var-file="env/dev.tfvars.local"

# Type 'yes' when prompted
# Estimated time: 10-20 minutes
```

#### Option B: Destroy in Reverse Order (Safer)

If the full destroy fails, use this staged approach:

```powershell
# 1. Destroy CI/CD Pipeline
terraform destroy -target=module.codepipeline -var-file="env/dev.tfvars.local"

# 2. Destroy CodeBuild Projects
terraform destroy -target=module.codebuild -var-file="env/dev.tfvars.local"

# 3. Destroy Compute Layer
terraform destroy -target=module.ecs -var-file="env/dev.tfvars.local"
terraform destroy -target=module.lambda -var-file="env/dev.tfvars.local"

# 4. Destroy API Gateway
terraform destroy -target=module.api_gateway -var-file="env/dev.tfvars.local"

# 5. Destroy ALB
terraform destroy -target=module.alb -var-file="env/dev.tfvars.local"

# 6. Destroy CloudFront (takes 15-20 minutes)
terraform destroy -target=module.cloudfront -var-file="env/dev.tfvars.local"

# 7. Destroy Data Layer
terraform destroy -target=module.rds -var-file="env/dev.tfvars.local"
terraform destroy -target=module.elasticache -var-file="env/dev.tfvars.local"
terraform destroy -target=module.dynamodb -var-file="env/dev.tfvars.local"

# 8. Destroy Cognito
terraform destroy -target=module.cognito -var-file="env/dev.tfvars.local"

# 9. Destroy ECR (requires empty repositories)
terraform destroy -target=module.ecr -var-file="env/dev.tfvars.local"

# 10. Destroy VPC Endpoints
terraform destroy -target=module.vpc_endpoints -var-file="env/dev.tfvars.local"

# 11. Destroy Secrets Manager
terraform destroy -target=module.secrets_manager -var-file="env/dev.tfvars.local"

# 12. Destroy IAM Roles
terraform destroy -target=module.iam -var-file="env/dev.tfvars.local"

# 13. Destroy Security Groups
terraform destroy -target=module.security_groups -var-file="env/dev.tfvars.local"

# 14. Destroy Networking (NAT Gateway, subnets, VPC)
terraform destroy -target=module.networking -var-file="env/dev.tfvars.local"

# 15. Destroy remaining resources
terraform destroy -var-file="env/dev.tfvars.local"
```

### Step 3: Manual Cleanup (If Needed)

Some resources may require manual deletion:

#### Empty S3 Buckets

```powershell
# S3 buckets with objects can't be auto-deleted
$BUCKET_NAME = "typerush-dev-frontend"

# Empty bucket
aws s3 rm s3://$BUCKET_NAME --recursive

# Delete bucket
aws s3 rb s3://$BUCKET_NAME --force

# Repeat for artifacts bucket
```

#### Empty ECR Repositories

```powershell
# List images
aws ecr list-images --repository-name typerush/game-service

# Delete all images
aws ecr batch-delete-image `
  --repository-name typerush/game-service `
  --image-ids "$(aws ecr list-images --repository-name typerush/game-service --query 'imageIds[*]' --output json)"

# Delete repository
aws ecr delete-repository --repository-name typerush/game-service --force
```

#### Delete CloudWatch Log Groups

```powershell
# List log groups
aws logs describe-log-groups --log-group-name-prefix /ecs/typerush-dev

# Delete log groups (if retention is set, they may not auto-delete)
aws logs delete-log-group --log-group-name /ecs/typerush-dev-game-service
aws logs delete-log-group --log-group-name /aws/lambda/typerush-dev-record-service
aws logs delete-log-group --log-group-name /aws/lambda/typerush-dev-text-service
```

#### Delete Route 53 Hosted Zone

```powershell
# Hosted zones cost $0.50/month until manually deleted
# List non-default records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Delete all non-default records (NS, SOA cannot be deleted)
# Then delete hosted zone
aws route53 delete-hosted-zone --id <zone-id>
```

#### Delete ACM Certificates

```powershell
# Certificates in use can't be deleted
# After CloudFront is destroyed, delete certificates
aws acm delete-certificate --certificate-arn <cert-arn> --region us-east-1
```

### Step 4: Verify Complete Deletion

```powershell
# Check Terraform state is empty
terraform state list
# Expected: empty or only remote backend

# Check AWS resources manually
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=typerush-dev"
aws ecs list-clusters --query "clusterArns[?contains(@,'typerush-dev')]"
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'typerush-dev')]"
aws s3 ls | Select-String "typerush-dev"
```

### Step 5: Cost Verification

```powershell
# Check AWS Cost Explorer (next day)
# Go to: https://console.aws.amazon.com/cost-management/home
# Verify daily costs drop to near $0

# Check for any ongoing charges
aws ce get-cost-and-usage `
  --time-period Start=$(Get-Date).AddDays(-7).ToString("yyyy-MM-dd"),End=$(Get-Date).ToString("yyyy-MM-dd") `
  --granularity DAILY `
  --metrics BlendedCost `
  --filter '{"Tags":{"Key":"Project","Values":["typerush-dev"]}}'
```

## Common Teardown Issues

### Issue: Terraform destroy fails on VPC (dependencies)

```powershell
# Error: VPC has dependencies (usually ENIs from Lambda or VPC endpoints)
# Solution: Wait 5-10 minutes for ENIs to detach, then retry

# Check for lingering ENIs
aws ec2 describe-network-interfaces `
  --filters "Name=vpc-id,Values=<vpc-id>"

# Force detach if needed (not recommended)
aws ec2 delete-network-interface --network-interface-id <eni-id>
```

### Issue: S3 bucket not empty error

```powershell
# Error: BucketNotEmpty
# Solution: Empty bucket first
aws s3 rm s3://typerush-dev-frontend --recursive

# If versioning enabled, delete versions
aws s3api list-object-versions --bucket typerush-dev-frontend `
  --query "Versions[].Key" --output text | ForEach-Object {
    aws s3api delete-object --bucket typerush-dev-frontend --key $_
}
```

### Issue: CloudFront distribution takes forever to delete

```powershell
# CloudFront can take 15-30 minutes to delete
# Must be disabled first, then deleted

# Check status
aws cloudfront get-distribution --id <distribution-id>

# If stuck, disable manually
aws cloudfront get-distribution-config --id <distribution-id> > config.json
# Edit config.json: set "Enabled": false
aws cloudfront update-distribution --id <distribution-id> --if-match <etag> --distribution-config file://config.json

# Wait for "Deployed" status, then retry destroy
```

### Issue: RDS snapshot already exists

```powershell
# Error: FinalSnapshotIdentifierAlreadyUsed
# Solution: Use different snapshot name or skip final snapshot

# Delete old snapshot
aws rds delete-db-snapshot --db-snapshot-identifier typerush-dev-final-snapshot

# Or skip final snapshot in Terraform
# Set skip_final_snapshot = true in RDS module
```

### Issue: ECR repository not empty

```powershell
# Delete all images first
aws ecr list-images --repository-name typerush/game-service |
  ConvertFrom-Json |
  Select-Object -ExpandProperty imageIds |
  ForEach-Object {
    aws ecr batch-delete-image `
      --repository-name typerush/game-service `
      --image-ids imageDigest=$_.imageDigest
  }
```

## Post-Teardown Checklist

- [ ] Terraform destroy completed successfully
- [ ] No resources remain in AWS Console
- [ ] S3 buckets are deleted or empty
- [ ] ECR repositories are deleted
- [ ] CloudWatch log groups deleted (if not needed)
- [ ] Route 53 hosted zone deleted (if not needed)
- [ ] ACM certificates deleted
- [ ] Daily AWS cost drops to $0 (check next day)
- [ ] SNS email subscriptions unsubscribed (if desired)
- [ ] Terraform state backed up
- [ ] Configuration and outputs documented
- [ ] RDS snapshot created (if needed for future)

## Snapshot Costs (If Keeping Backups)

If you created snapshots before destroying:

### RDS Snapshot

- **Cost**: $0.10/GB/month
- **Example**: 20GB database = $2/month
- **Retention**: Keep until you're sure you don't need it

### Delete Snapshots Later

```powershell
# List snapshots
aws rds describe-db-snapshots --query "DBSnapshots[?contains(DBSnapshotIdentifier,'typerush-dev')]"

# Delete snapshot when done
aws rds delete-db-snapshot --db-snapshot-identifier typerush-dev-final-snapshot-20240123
```

## Redeployment

If you want to redeploy the infrastructure later:

```powershell
# Full redeployment
terraform apply -var-file="env/dev.tfvars.local"

# Restore RDS from snapshot (modify RDS module)
snapshot_identifier = "typerush-dev-final-snapshot-20240123"
```

## Important Notes

- **Billing Lag**: AWS billing has a 1-day delay. Check costs the next day.
- **Hidden Costs**: Some services (EBS snapshots, S3 logs) may persist.
- **Terraform State**: Keep terraform.tfstate backed up if you plan to redeploy.
- **Learning Value**: Document what you learned before destroying.
- **Production**: NEVER use this teardown procedure in production without extensive testing.

## References

- [Terraform Destroy](https://www.terraform.io/docs/commands/destroy.html)
- [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)
- [AWS Billing Alerts](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html)

## Final Recommendations

### What to Keep (Minimal Cost)

- RDS snapshot (~$2/month)
- Terraform state backup (free, local)
- Configuration documentation (free)
- Learning notes (priceless!)

### What to Delete Immediately

- All running compute (ECS, Lambda with ENIs)
- NAT Gateway ($32/month)
- VPC Endpoints ($29/month)
- RDS instance ($14/month)
- ElastiCache ($12/month)
- ALB ($16/month)

### Budget Alert (Recommended)

```powershell
# Set up billing alarm to alert if costs exceed $1/day
aws cloudwatch put-metric-alarm `
  --alarm-name typerush-dev-budget-alert `
  --alarm-description "Alert if daily costs exceed $1" `
  --metric-name EstimatedCharges `
  --namespace AWS/Billing `
  --statistic Maximum `
  --period 86400 `
  --evaluation-periods 1 `
  --threshold 1.0 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions <sns-topic-arn>
```

---

**Congratulations!** You've completed the TypeRush AWS infrastructure learning project. Remember to destroy resources when done to avoid ongoing costs. Happy learning! 🚀
