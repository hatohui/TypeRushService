# TypeRush Service - AWS Infrastructure

Real-time multiplayer typing game built on AWS with automated CI/CD from GitLab.

---

## 🚀 Quick Start

### Infrastructure is Ready!

All AWS infrastructure has been deployed. To enable automated deployments:

```bash
# 1. Test infrastructure
./test-infrastructure.sh

# 2. Set up GitLab CI/CD (5 minutes)
cat GITLAB_QUICK_START.md

# 3. Deploy services
git push origin main  # Automatic deployment!
```

---

## 📚 Documentation

| Document                                                                         | Purpose                           |
| -------------------------------------------------------------------------------- | --------------------------------- |
| **[SETUP_SUMMARY.md](SETUP_SUMMARY.md)**                                         | Current status & next steps       |
| **[GITLAB_QUICK_START.md](GITLAB_QUICK_START.md)**                               | 5-minute GitLab CI/CD setup       |
| **[docs/GITLAB_CODEPIPELINE_SETUP.md](docs/GITLAB_CODEPIPELINE_SETUP.md)**       | Complete GitLab integration guide |
| **[VERIFICATION_AND_DEPLOYMENT_GUIDE.md](VERIFICATION_AND_DEPLOYMENT_GUIDE.md)** | Test & verify infrastructure      |
| **[test-infrastructure.sh](test-infrastructure.sh)**                             | Automated verification script     |

---

## 🏗️ Architecture

```
Frontend (React + Vite)
  ↓ CloudFront
  ↓ S3

API Gateway HTTP
  ↓ Lambda Functions
  ├─ Record Service (Node.js + Prisma + RDS PostgreSQL)
  └─ Text Service (Python + DynamoDB + Bedrock)

API Gateway WebSocket
  ↓ Internal ALB
  ↓ ECS Fargate
  └─ Game Service (Node.js + Socket.io + Redis + RDS)
```

---

## 🔧 Infrastructure Components

✅ **Deployed via Terraform:**

- VPC with public/private subnets
- RDS PostgreSQL (game records)
- ElastiCache Redis (real-time state)
- DynamoDB (text corpus)
- ECS Fargate (Game Service)
- Lambda Functions (Record & Text Services)
- API Gateway (HTTP & WebSocket)
- CloudFront + S3 (Frontend)
- Cognito (Authentication)
- CodePipeline + CodeBuild (CI/CD)

---

## 🚀 CI/CD Pipeline

**Automated deployments from GitLab:**

```
git push origin main
    ↓
GitLab → AWS CodePipeline
    ↓
    ├─ Game Service: Docker → ECR → ECS
    ├─ Record Service: Node.js → Lambda
    ├─ Text Service: Python → Lambda
    └─ Frontend: React → S3 → CloudFront
```

**Setup in 3 steps:**

1. Create GitLab personal access token
2. Create AWS CodeStar connection
3. Run `terraform apply`

See [GITLAB_QUICK_START.md](GITLAB_QUICK_START.md) for details.

---

## 📊 Infrastructure Outputs

```bash
cd infras && terraform output

# Key endpoints:
# - cloudfront_distribution_url: Frontend URL
# - http_api_endpoint: REST API
# - websocket_api_endpoint: WebSocket API
# - cognito_hosted_ui_url: Authentication
```

---

## 🧪 Testing

### Automated Test

```bash
./test-infrastructure.sh
```

### Manual Tests

```bash
# Test HTTP API
HTTP_API=$(cd infras && terraform output -raw http_api_endpoint)
curl $HTTP_API/records/health

# Test CloudFront
CLOUDFRONT=$(cd infras && terraform output -raw cloudfront_distribution_url)
curl -I $CLOUDFRONT

# Check ECS service
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service
```

---

## 🔐 Environment Variables

Configured in AWS:

- **Lambda Functions**: Environment variables set via Terraform
- **ECS Tasks**: Environment variables in task definition
- **Secrets**: Stored in AWS Secrets Manager
  - RDS password
  - Redis AUTH token

---

## 💰 Cost Estimate

**~$145/month** (~$5/day) for dev environment:

- Infrastructure: ~$120-135/month
- CI/CD: ~$12/month

**Cost optimization:**

```bash
# Scale down when not in use
aws ecs update-service --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service --desired-count 0
```

---

## 🛠️ Development

### Local Development

```bash
# Game Service (ECS)
cd services/game-service
npm install
npm run dev

# Record Service (Lambda)
cd services/record-service
npm install
npm run dev

# Text Service (Lambda)
cd services/text-service
pip install -r requirements.txt
python lambda_handler.py

# Frontend
cd frontend
npm install
npm run dev
```

### Deploy to AWS

**Option 1: Automatic (via GitLab)**

```bash
git push origin main
```

**Option 2: Manual**

```bash
# Game Service
aws codepipeline start-pipeline-execution --name typerush-dev-game-service

# Or see VERIFICATION_AND_DEPLOYMENT_GUIDE.md for manual deployment
```

---

## 📁 Project Structure

```
TypeRushService/
├── infras/                    # Terraform infrastructure
│   ├── dev.auto.tfvars       # Configuration
│   ├── main.tf
│   └── modules/              # Infrastructure modules
├── services/
│   ├── game-service/         # ECS Fargate service
│   │   ├── buildspec.yml    # CI/CD build spec
│   │   └── src/
│   ├── record-service/       # Lambda function
│   │   ├── buildspec.yml
│   │   └── src/
│   └── text-service/         # Lambda function
│       ├── buildspec.yml
│       └── lambda_handler.py
├── frontend/                  # React + Vite
│   ├── buildspec.yml
│   └── src/
└── docs/                      # Documentation
```

---

## 🐛 Troubleshooting

### Infrastructure Issues

```bash
# Run verification script
./test-infrastructure.sh

# Check Terraform state
cd infras && terraform state list
```

### Deployment Issues

```bash
# Check pipeline status
aws codepipeline get-pipeline-state --name typerush-dev-game-service

# View build logs
aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow

# Check service logs
aws logs tail /ecs/typerush-dev-game-service --follow
```

See [docs/GITLAB_CODEPIPELINE_SETUP.md](docs/GITLAB_CODEPIPELINE_SETUP.md) for detailed troubleshooting.

---

## 📖 Additional Resources

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [GitLab CI/CD with AWS](https://docs.gitlab.com/ee/ci/cloud_deployment/aws.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🎯 Current Status

✅ **Infrastructure**: Deployed and tested  
⏳ **CI/CD**: Ready to configure (5 minutes)  
⏳ **Services**: Ready to deploy (automatic after CI/CD setup)

**Next step:** [GITLAB_QUICK_START.md](GITLAB_QUICK_START.md)

---

## 📞 Support

- Infrastructure issues: Check [VERIFICATION_AND_DEPLOYMENT_GUIDE.md](VERIFICATION_AND_DEPLOYMENT_GUIDE.md)
- CI/CD setup: Check [docs/GITLAB_CODEPIPELINE_SETUP.md](docs/GITLAB_CODEPIPELINE_SETUP.md)
- General questions: Review [SETUP_SUMMARY.md](SETUP_SUMMARY.md)

---

**Ready to deploy? Start with [GITLAB_QUICK_START.md](GITLAB_QUICK_START.md)!** 🚀
