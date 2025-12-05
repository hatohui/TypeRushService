# TypeRush Architecture Overview

## 🎯 System Purpose

TypeRush is a typing speed game application with real-time gameplay, leaderboards, personal records tracking, and AI-generated text challenges. The architecture supports high-traffic gaming sessions with sub-second latency requirements.

## 🌐 User Access and Edge Layer

### CloudFront CDN

- **Purpose**: Global content delivery network for static assets and API caching
- **Features**:
  - Edge locations for low-latency content delivery
  - HTTPS/TLS termination
  - Custom domain support
  - Cache behaviors for different content types
  - Origin failover configuration
- **Origins**:
  - Primary: S3 bucket for frontend static files
  - Secondary: API Gateway for backend APIs

### AWS WAF (Web Application Firewall)

- **Purpose**: Basic protection for dev environment
- **Rules** (minimal for dev):
  - Rate limiting (basic - 5000 req/5min)
  - AWS Managed Rules (Core Rule Set only)
- **Integration**: Attached to CloudFront distribution
- **Note**: Production-grade rules (SQL injection, XSS, geo-blocking) can be added later

### Route 53 (DNS Management)

- **Purpose**: Domain name system and health checks
- **Records**:
  - A/AAAA records pointing to CloudFront
  - Health checks for ALB endpoints
  - Failover routing policies
- **Domain**: `typerush.com` (or custom domain)

### S3 (Frontend Static Hosting)

- **Purpose**: Host React/Next.js frontend application
- **Configuration**:
  - Static website hosting enabled
  - CloudFront Origin Access Identity (OAI) for secure access
  - Versioning optional (dev - can enable if needed)
- **Content**: HTML, CSS, JavaScript, images, fonts

### API Gateway

- **Purpose**: Unified API management layer with additional features
- **HTTP API Gateway**:
  - Request/response transformation
  - API throttling (dev: 1000 req/sec burst, 500 steady state)
  - Request validation
  - CORS configuration
  - **VPC Link Integration**: Private connection to internal ALB for Game Service REST endpoints
  - **Direct Lambda Integration**: Synchronous invocation for Record and Text Services
- **WebSocket API Gateway**:
  - Real-time bidirectional communication for multiplayer gameplay (real-time score streaming, player matching)
  - Connection management (connect, disconnect, message routing)
  - **VPC Link Integration**: Routes WebSocket traffic to internal ALB → Game Service ECS
  - Game Service handles WebSocket logic directly in the application
- **Stage**: Development (single stage)

### AWS Cognito

- **Purpose**: User authentication and authorization
- **User Pool**:
  - Email/password authentication
  - Basic password policies (min 8 chars)
  - MFA optional (dev - can enable for testing)
  - Custom attributes (player stats, preferences)
- **Identity Pool**: Optional for dev (enable if frontend needs AWS credentials)
- **Integration**: Frontend → Cognito → API Gateway

## 🏗️ Core Architecture

### Region & High Availability

- **Region**: `ap-southeast-1` (Singapore)
- **Single-AZ Deployment**: Development environment (cost-optimized)
- **Network Architecture**: Public and Private subnet separation

### Virtual Private Cloud (VPC) and Networking

#### Public Subnet (DMZ)

- **NAT Gateway**: Single NAT Gateway (required for ECS/Lambda initialization)
  - Purpose: Enables private subnet resources to access internet for:
    - ECS task startup and image pulls
    - Lambda ENI creation during cold starts
    - Package updates and external API calls
  - Note: Cannot be eliminated even with VPC endpoints due to ECS/Lambda requirements
  - Cost: ~$32.40/month + data transfer

#### Private Subnet (Application Layer)

- **Internal Application Load Balancer (ALB)**:
  - Private load balancer (not internet-facing)
  - Target for API Gateway VPC Link
  - Routes to Game Service ECS tasks
  - Health checks on `/health` endpoint
- **VPC Link**: Connects API Gateway (HTTP + WebSocket) to internal ALB securely
- **ECS Cluster**: Runs Game Service containerized microservice (handles REST + WebSocket)
- **Lambda Functions**:
  - Record Service (directly invoked by API Gateway HTTP API)
  - Text Service (directly invoked by API Gateway HTTP API)
- **ElastiCache Redis Cluster**: Game session state and real-time score management
  - Used by Game Service for stateless scaling
  - Single-node cluster (cache.t4g.micro) for dev
  - Stores active game sessions and WebSocket connection metadata
- **RDS PostgreSQL Instance**: Single database for all persistent data (Record Service only)
- **VPC Interface Endpoints**: Secure AWS service access without internet traversal
  - **Secrets Manager**: DB credentials retrieval for ECS and Lambda
  - **Bedrock Runtime**: AI text generation for Text Service
  - **ECR API + ECR Docker**: Container image pulls for ECS (2 endpoints)
  - Note: CloudWatch Logs uses NAT Gateway for dev (cost optimization)
- **VPC Gateway Endpoint**:
  - DynamoDB endpoint (cost-effective access for Text Service)

## ⚙️ Application Backend Services (Microservices Architecture)

### 1. Game Service (Node.js + Express + Drizzle ORM)

- **Location**: `/services/game-service`
- **Runtime**: ECS Fargate containers (behind internal ALB)
- **Data Storage**: ElastiCache Redis only (no persistent database)
- **Purpose**:
  - **Real-time gameplay**: WebSocket connections for live score streaming and player matching
  - Game session management and coordination (ephemeral state in ElastiCache)
  - In-game text retrieval (calls Text Service API)
  - After game completion, sends results to Record Service for persistence
  - REST API endpoints for game logic and session management
- **Database Schema** (Drizzle ORM):
  ```typescript
  - account table: id, email, firstName, lastName, currency, balance
  - Uses pgEnum for currency types (USD, EUR, GBP)
  ```
- **Technology Stack**:
  - Express.js for REST API routing
  - WebSocket support for real-time gameplay (ws or socket.io)
  - Drizzle ORM for type-safe database queries
  - PostgreSQL for relational data
- **Real-time Communication**: Handles WebSocket connections directly (API Gateway WebSocket → VPC Link → ALB → ECS)
- **State Management**:
  - WebSocket connections: Managed by API Gateway + in-memory in ECS
  - Game session state: ElastiCache Redis (for stateless ECS scaling)
  - Real-time scores: ElastiCache sorted sets
  - Persistent data: Sent to Record Service Lambda → RDS PostgreSQL after game completion
- **Access Pattern**:
  - REST: API Gateway HTTP API → VPC Link → Internal ALB → ECS Tasks
  - WebSocket: API Gateway WebSocket API → VPC Link → Internal ALB → ECS Tasks
- **Deployment**: ECS Fargate with basic auto-scaling
  - Desired count: 1
  - Min: 1 (cannot scale to 0 with ALB)
  - Max: 2 (basic scaling for dev)
  - Scaling metric: CPU > 70% for 2 minutes

### 2. Record Service (NestJS + Prisma)

- **Location**: `/services/record-service`
- **Runtime**: AWS Lambda
- **Database**: RDS PostgreSQL (separate instance from Game Service)
- **Purpose**: Persistence REST API for game records and user accounts
  - **User account management**: email, username, profile data, currency, balance
  - Personal records and statistics tracking
  - Match history storage and retrieval
  - Leaderboards (query and ranking)
  - Achievement system
  - Multi-player match results persistence
- **Database Schema** (Prisma):
  ```prisma
  - Account: User accounts (id, email, username, currency, balance, createdAt)
  - Mode: Game modes (time-based, word-based, etc.)
  - PersonalRecord: Individual player best scores (accountId, accuracy, raw WPM)
  - MatchHistory: Match session records with mode reference
  - MatchParticipant: Player results per match (rank, accuracy, WPM)
  - Achievement: Achievement definitions with WPM criteria
  - UserAchievement: Junction table for user unlocked achievements
  ```
- **Technology Stack**:
  - NestJS for structured, scalable architecture
  - Prisma ORM for database access
  - RESTful API with global exception filters
- **Access Pattern**: API Gateway → Direct Lambda Invocation (no VPC Link needed)
- **Secrets Access**: Lambda execution role retrieves RDS credentials from Secrets Manager
- **Deployment**: AWS Lambda (event-driven, serverless for cost optimization)

### 3. Text Service (Python + FastAPI)

- **Location**: `/services/text-service`
- **Runtime**: AWS Lambda
- **AI Integration**: AWS Bedrock via VPC Interface Endpoint
- **Data Storage**: DynamoDB (via VPC Gateway Endpoint)
- **Purpose**: AI text generation and storage for in-game text challenges
  - Generate typing challenge texts using AI (Bedrock)
  - Evaluate text complexity and difficulty
  - Store generated texts in DynamoDB for quick retrieval
  - **Serve texts to Game Service**: Game Service calls this API to get random texts for game sessions
  - Pre-generate text batches during off-peak hours
- **Technology Stack**:
  - FastAPI for high-performance async API
  - AWS Bedrock for AI text generation (Claude/Llama models)
  - DynamoDB for NoSQL text storage with fast lookups
  - Pydantic for data validation
- **Access Pattern**: API Gateway → Direct Lambda Invocation (no VPC Link needed)
- **Secrets Access**: Lambda execution role retrieves Bedrock API keys from Secrets Manager
- **Deployment**: AWS Lambda (serverless, on-demand text generation with Bedrock integration)

## 🗄️ Data Layer

### RDS PostgreSQL (Single Instance)

**Record Service Database**

- **User accounts**: email, username, profile, currency, balance
- **Game statistics and records**: personal bests, achievements
- **Match history**: complete game session data with relational integrity
- **Leaderboards**: aggregated player rankings
- Port: 5432 (default)
- Engine: PostgreSQL 17
- Instance: db.t3.micro (dev - minimal cost)
- Single-AZ deployment (dev)

**Why Single Database?**

- Game Service doesn't persist data (uses ElastiCache for ephemeral state)
- Record Service owns ALL persistent data (accounts + game history)
- Simplified architecture with one database to manage
- Cost savings: ~$14.40/month (1 instance vs 2)
- Note: Game Service sends completed game data to Record Service for persistence

### DynamoDB

- **Purpose**: Text challenge storage
- **Access**: VPC Gateway Endpoint (no NAT costs)
- **Billing Mode**: On-Demand (dev - pay per request)
- **Schema Design** (inferred):
  - Partition Key: `text_id` or `difficulty_level`
  - Attributes: generated text, metadata, difficulty score
- **Use Case**: Fast, scalable text retrieval for game sessions

### ElastiCache Redis

- **Purpose**: Game session state and real-time data caching
- **Instance Type**: cache.t4g.micro (ARM-based, cost-optimized)
- **Deployment**: Single-node cluster in single AZ (dev only)
- **Use Cases**:
  - Active game session state (allows ECS tasks to be stateless)
  - Real-time player scores (Redis sorted sets for leaderboards)
  - WebSocket connection metadata (for reconnection handling)
  - Rate limiting counters (per-user API throttling)
- **Access**: Game Service ECS tasks via private subnet security group
- **Data Persistence**: Disabled for dev (ephemeral cache)
- **Cost**: ~$12.41/month

## 🔐 Security Architecture

### Network Security

- **Public Subnet**: Only ALB exposed to internet
- **Private Subnet**: All application resources isolated
- **Security Groups**:
  1. ALB Security Group: Allows HTTP/HTTPS from internet
  2. ECS Service Security Group: Allows traffic only from ALB
  3. RDS Security Group: Allows PostgreSQL (5432) only from ECS services
  4. VPC Endpoint Security Group: Allows HTTPS from ECS services

### Secrets Management

- **AWS Secrets Manager**: Stores sensitive credentials
  - `typerush/record-db/credentials`: Record Service RDS credentials (username, password, host, port, database)
  - `typerush/elasticache/auth-token`: ElastiCache Redis authentication token
  - Note: Bedrock uses IAM roles, not API keys (no secret needed)
- **Access Pattern**:
  - **ECS Game Service**: Task Role retrieves game-db secret at startup via VPC Interface Endpoint
  - **Lambda Record Service**: Execution Role retrieves record-db secret during cold start via VPC Interface Endpoint
  - **Lambda Text Service**: No Secrets Manager access needed (uses IAM for Bedrock)
  - Secrets are injected as environment variables (not hardcoded)
- **VPC Integration**: Secrets Manager VPC Interface Endpoint provides private access
- **Cost**: $0.40/secret/month × 2 secrets = $0.80/month (RDS + ElastiCache)

### IAM Roles (Least Privilege)

1. **ECS Task Execution Role**:
   - Pull images from ECR via VPC Interface Endpoint
   - Write logs to CloudWatch via VPC Interface Endpoint
2. **Game Service Task Role**:
   - Read ElastiCache auth token from Secrets Manager VPC Interface Endpoint
   - Write logs to CloudWatch (via NAT Gateway for dev)
   - VPC permissions for network access
   - ElastiCache read/write access (game session state)
   - Invoke Text Service Lambda (to fetch in-game texts)
   - Invoke Record Service Lambda (to save match results after game completion)
3. **Record Service Lambda Execution Role**:
   - Read from Record DB secret via Secrets Manager VPC Interface Endpoint
   - Write logs to CloudWatch via VPC Interface Endpoint
   - VPC permissions (ENI creation for VPC Lambda)
4. **Text Service Lambda Execution Role**:
   - Read/Write DynamoDB via VPC Gateway Endpoint
   - Invoke Bedrock models via Bedrock VPC Interface Endpoint (uses IAM, not API keys)
   - Write logs to CloudWatch (via NAT Gateway for dev)
   - VPC permissions (ENI creation for VPC Lambda)
   - No Secrets Manager access needed (Bedrock authentication via IAM)

## 📊 Observability & Monitoring

### CloudWatch

- **Log Groups**: Per-service log aggregation
  - `/ecs/game-service` (ECS Fargate logs)
  - `/aws/lambda/record-service` (Lambda logs)
  - `/aws/lambda/text-service` (Lambda logs)
- **Log Retention**: 7 days (dev - cost optimization)
- **Log Access**: Via NAT Gateway (dev) - no CloudWatch VPC endpoint to save $7.20/month
- **Metrics**: Basic AWS metrics (minimal custom metrics for dev)
- **Alarms**: Essential alarms only
  - ECS service unhealthy (critical)
  - RDS connections > 80% max
  - Lambda errors > 10 in 5 minutes
  - ElastiCache CPU > 75%

### SNS Topics

- **Purpose**: Basic alerting for dev environment
- **Delivery**: Email notifications only (no SMS for dev)
- **Integration**: CloudWatch Alarms → SNS → Developer email

## 🚀 Deployment & CI/CD Pipeline

### AWS CodePipeline

- **Purpose**: Orchestrate the entire CI/CD workflow
- **Stages**:
  1. **Source**: Triggered by GitLab/GitHub webhook on push to `main` branch
  2. **Build**: Invoke CodeBuild for Docker image creation
  3. **Deploy**: Update ECS services with new task definitions
  4. **Approval**: Manual approval gate for production (optional)
- **Artifacts**: S3 bucket for build artifacts and deployment packages

### AWS CodeBuild

- **Purpose**: Build and test Docker images
- **Build Specs** (per service):
  - Install dependencies
  - Run unit tests
  - Build Docker images
  - Tag images with commit SHA and `latest`
  - Push to ECR
  - Update ECS task definitions
- **Build Environment**:
  - Docker runtime
  - Privileged mode enabled
  - Environment variables from Secrets Manager

### Amazon ECR (Elastic Container Registry)

- **Purpose**: Private Docker image repository
- **Repositories**:
  - `typerush/game-service`
  - `typerush/record-service`
  - `typerush/text-service`
- **Features**:
  - Image scanning for vulnerabilities
  - Lifecycle policies (retain last 10 images)
  - Cross-region replication (optional)
- **Access**: IAM-based authentication from CodeBuild and ECS

### GitLab Integration

- **Repository**: TypeRushService mono-repo
- **Webhooks**: Push events to CodePipeline
- **Branching Strategy**:
  - `main`: Production deployments
  - `develop`: Staging environment
  - `feature/*`: Feature branches (no auto-deploy)

### Deployment Flow

```
Git Push → GitLab Webhook → CodePipeline Triggered
    ↓
CodeBuild Project (per service)
    ↓
    ├─ npm install / pip install
    ├─ npm test / pytest
    ├─ docker build -t <service>:${COMMIT_SHA}
    ├─ docker push ECR
    └─ Update ECS Task Definition
    ↓
ECS Service Update (Rolling deployment)
    ↓
Health Checks Pass → Deployment Complete
```

## 📐 Architecture Decisions & Rationale

### Health Check Endpoints

**All services expose health endpoints**:

- **Game Service**: `GET /health` (ALB target group health check)
- **Record Service**: `GET /health` or `GET /api/health` (Lambda warmup endpoint)
- **Text Service**: `GET /health` or `GET /api/health` (Lambda warmup endpoint)

**Configuration**:

- ALB health check: `/health` on port 3000 (Game Service)
- API Gateway health check: Optional for Lambda integrations
- Interval: 30 seconds, Timeout: 5 seconds, Healthy threshold: 2, Unhealthy threshold: 3

### CORS Configuration

**Allowed Origins** (API Gateway):

- `https://typerush.com` (production frontend)
- `http://localhost:3000` (local development)
- `https://*.cloudfront.net` (CloudFront distributions)

**Methods**: GET, POST, PUT, DELETE, OPTIONS  
**Headers**: Content-Type, Authorization, X-Requested-With

### Why Internal ALB with API Gateway VPC Link?

- **Security**: Game Service ECS tasks are not exposed to the internet directly
- **Centralized API Management**: API Gateway handles authentication, throttling, and monitoring
- **Private Network**: All traffic from API Gateway to backend stays within AWS private network (via VPC Link/PrivateLink)
- **Cost Optimization**: No need for internet-facing ALB with WAF charges on ALB (WAF only on CloudFront)

### Why WebSocket API Gateway to ECS (Not Lambda)?

- **Stateful Connections**: Game Service maintains WebSocket connection state in ECS containers
- **Low Latency**: Direct WebSocket handling in ECS without Lambda cold starts
- **Session Management**: ECS containers can hold game session state in memory
- **API Gateway Benefits**: Still get connection management, authentication, and auto-scaling at the edge
- **Architecture**: API Gateway WebSocket → VPC Link → Internal ALB → Game Service ECS

### Why Mixed ECS and Lambda Architecture?

- **Game Service (ECS)**:
  - Handles both REST API and WebSocket connections
  - Stateful real-time gameplay (score streaming, player matching)
  - Consistent compute for low-latency requirements
  - Container reuse for connection state management
- **Record Service (Lambda)**:
  - Stateless persistence REST API
  - CRUD operations benefit from serverless cost optimization
  - Automatic scaling based on request volume
- **Text Service (Lambda)**:
  - On-demand text generation with Bedrock
  - Event-driven, serverless execution
  - Called by Game Service to fetch in-game texts

### Why Single PostgreSQL Database?

- **Game Service is stateless**: Only handles real-time gameplay via ElastiCache
- **Record Service owns all persistent data**: Accounts, game history, leaderboards, achievements
- **Simplified operations**: One database to backup, monitor, and scale
- **Cost optimization**: ~$14.40/month savings (one db.t3.micro instead of two)
- **Clear separation**: Ephemeral state (ElastiCache) vs Persistent state (RDS)
- **Microservices pattern**: Record Service is the single source of truth for all persisted data

### Why DynamoDB for Text Service?

- NoSQL better suited for simple key-value text retrieval
- Infinite scalability without capacity planning
- Lower latency for random text fetching
- Cost-effective for read-heavy workload

### Why ElastiCache Redis for Game Service?

- **Stateless ECS Scaling**: Allows ECS tasks to scale horizontally without losing game state
- **WebSocket Reconnection**: Enables clients to reconnect and resume game sessions
- **Real-time Leaderboards**: Redis sorted sets provide O(log N) leaderboard queries
- **Low Latency**: Sub-millisecond read/write for game state updates
- **Temporary Data**: Game sessions are ephemeral; don't need durable storage until game ends
- **Alternative**: Could use in-memory only for dev, but limits scaling and reconnection

### Why VPC Endpoints?

- **Security**: No internet traversal for AWS API calls
- **Cost**:
  - **Interface Endpoints**: Pay per endpoint + data processed (~$7.20/month each)
  - **Gateway Endpoints**: Free for S3 and DynamoDB (no hourly charge, no data processing charge)
  - **Trade-off**: VPC endpoints reduce NAT Gateway data transfer, but NAT is still required
- **Performance**: Lower latency to AWS services within AWS network
- **Compliance**: Data doesn't leave AWS network
- **Dev Configuration**:
  - **Interface Endpoints** (Required): Secrets Manager, Bedrock Runtime, ECR API, ECR Docker
  - **Gateway Endpoints** (Free): DynamoDB, S3
  - **Skipped for Dev**: CloudWatch Logs (uses NAT to save $7.20/month)

### Why NAT Gateway is Still Required?

- **ECS Task Initialization**: ECS tasks need internet access during startup for:
  - AWS API calls before VPC endpoints are fully available
  - Docker layer downloads from S3 (even with S3 endpoint, some traffic goes through NAT)
  - Initial service mesh setup
- **Lambda Cold Starts**: VPC Lambda functions require internet access for ENI creation
- **Package Updates**: Operating system security patches and package manager updates
- **External APIs**: Any external service calls (if needed)
- **Cost Reality**: NAT Gateway ($32.40/month) is cheaper than adding more VPC Interface Endpoints
- **Conclusion**: Cannot eliminate NAT Gateway even with comprehensive VPC endpoint coverage

## 🔄 Traffic Flow

### Frontend Traffic (Static Assets)

```
Internet User
    ↓
Route 53 (DNS: typerush.com)
    ↓
CloudFront CDN (Edge Locations)
    ↓
WAF (Security Filtering)
    ↓
S3 Bucket (Frontend Build: index.html, *.js, *.css)
```

### Backend API Traffic (with Cognito Auth)

```
Internet User
    ↓
Route 53 (DNS: api.typerush.com)
    ↓
CloudFront CDN (API Caching)
    ↓
WAF (Rate Limiting + SQL Injection Protection)
    ↓
API Gateway HTTP API (Request Validation + Throttling)
    ↓
Cognito (JWT Token Validation) ← User Login/Signup
    ↓
[Routing Decision]
    ↓
    ├─→ /api/game/*   → VPC Link → Internal ALB (Private Subnet) → Game Service (ECS) → RDS Postgres (Game DB)
    ├─→ /api/record/* → Direct Lambda Invocation → Record Service (Lambda in VPC) → RDS Postgres (Record DB)
    └─→ /api/text/*   → Direct Lambda Invocation → Text Service (Lambda in VPC) → Bedrock + DynamoDB
```

### WebSocket Traffic (Real-time Gameplay)

```
Internet User (WebSocket Client)
    ↓
Route 53 (DNS: ws.typerush.com)
    ↓
API Gateway WebSocket API (Connection Management + Auth)
    ↓
Cognito (JWT Token Validation on $connect)
    ↓
VPC Link (Private Network Connection)
    ↓
Internal ALB (Private Subnet)
    ↓
Game Service ECS Tasks (WebSocket Handler)
    ↓
    ├─→ Real-time score streaming
    ├─→ Player matching and game session coordination
    ├─→ Game state management (in-memory)
    ├─→ RDS Postgres (Game DB) - persist game sessions
    ├─→ Text Service Lambda - fetch in-game texts via HTTP
    └─→ Record Service Lambda - save match results via HTTP (post-game)
```

### CI/CD Deployment Flow

```
Developer Push → GitLab Repository
    ↓
Webhook Trigger → CodePipeline
    ↓
CodeBuild (Build + Test + Docker Image)
    ↓
Push Image → ECR
    ↓
Update ECS Task Definition → Rolling Update
    ↓
Health Checks → Production Traffic
```

## 📋 Terraform Module Structure

```
infras/
├── main.tf              # Root orchestration
├── variables.tf         # Input variables
├── outputs.tf           # Exported values
├── provider.tf          # AWS provider config
├── terraform.tf         # Terraform version constraints
├── backend.tf           # S3 backend for state management
├── env/
│   ├── prod.tfvars      # Production variables
│   ├── staging.tfvars   # Staging environment
│   └── dev.tfvars       # Development environment
└── modules/
    ├── 01-networking/         # VPC, Subnets, IGW, NAT, Route Tables
    ├── 02-security-groups/    # All Security Groups
    ├── 03-iam/                # IAM roles and policies for all services
    ├── 04-s3/                 # S3 buckets (frontend, artifacts, logs)
    ├── 05-route53/            # DNS zones and records
    ├── 06-acm/                # SSL/TLS certificates
    ├── 07-cloudfront/         # CDN distribution + OAI
    ├── 08-waf/                # WAF rules and web ACLs
    ├── 09-cognito/            # User pools and identity pools
    ├── 10-api-gateway/        # HTTP API + WebSocket API Gateway
    ├── 10a-vpc-link/          # VPC Link for API Gateway to internal ALB
    ├── 11-alb/                # Internal Application Load Balancer + Target Groups
    ├── 12-rds/                # 2 PostgreSQL instances + subnet groups
    ├── 13-dynamodb/           # DynamoDB tables (texts, sessions)
    ├── 14-secrets-manager/    # Secrets for DB passwords, API keys
    ├── 15-vpc-endpoints/      # PrivateLink endpoints (Bedrock, Secrets, etc.)
    ├── 16-ecr/                # Container registries for 3 services
    ├── 17-ecs/                # ECS Cluster + Fargate services
    ├── 18-lambda/             # Lambda functions (alternative compute)
    ├── 19-codebuild/          # Build projects for CI/CD
    ├── 20-codepipeline/       # Deployment pipelines
    ├── 21-cloudwatch/         # Log groups, metrics, dashboards
    ├── 22-sns/                # SNS topics for alerts
    └── 23-eventbridge/        # Event rules for automation (optional)
```

## ✅ Implementation Checklist

### Phase 1: Foundation & Core Networking

- [x] Create overview document
- [ ] **Module 01: Networking** (`modules/01-networking`)

  - [ ] VPC (CIDR: 10.0.0.0/16)
  - [ ] Public Subnet: 1 AZ (10.0.1.0/24) - dev only
  - [ ] Private Subnet: 1 AZ (10.0.101.0/24) - dev only
  - [ ] Database Subnet: 1 AZ (10.0.201.0/24) - single RDS instance
  - [ ] ElastiCache Subnet: 1 AZ (10.0.202.0/24) - dev only
  - [ ] Internet Gateway
  - [ ] NAT Gateway (single instance - required for ECS/Lambda initialization)
  - [ ] Route Tables + Associations
  - [ ] VPC Flow Logs optional (dev - enable if debugging needed)

- [ ] **Module 02: Security Groups** (`modules/02-security-groups`)
  - [ ] CloudFront → WAF → API Gateway (no SG needed, managed service)
  - [ ] Internal ALB SG: Allow 80/443 from VPC Link ENIs (private subnet)
  - [ ] ECS SG: Allow internal ALB SG only on application port 3000
  - [ ] Lambda SG (for VPC Lambdas): Allow outbound to RDS, VPC Endpoints, DynamoDB
  - [ ] RDS SG: Allow Lambda SG only on port 5432 (Record Service Lambda only)
  - [ ] ElastiCache SG: Allow ECS SG only on port 6379 (Redis)
  - [ ] VPC Interface Endpoint SG: Allow ECS SG + Lambda SG on port 443 (4 endpoints)
  - [ ] VPC Link SG: Allow API Gateway service (managed by AWS)
  - [ ] Bastion SG: SSH from specific IPs (optional)

### Phase 2: Identity & Access Management

- [x] **Module 03: IAM** (`modules/03-iam`) ✅ **COMPLETED**
  - [x] ECS Task Execution Role (ECR pull via VPC endpoints, CloudWatch Logs via NAT)
  - [x] Game Service Task Role (ElastiCache, Secrets Manager, Lambda invoke, CloudWatch Logs)
  - [x] Record Service Lambda Execution Role (RDS, Secrets Manager, VPC access, CloudWatch Logs)
  - [x] Text Service Lambda Execution Role (DynamoDB, Bedrock via IAM, VPC access, CloudWatch Logs)
  - [x] CodeBuild Service Role (ECR push, S3 artifacts, Secrets Manager)
  - [x] CodePipeline Service Role (CodeBuild trigger, ECS deploy, Lambda update)
  - [x] CloudFront OAI for S3 access
  - [x] **Updated:** Secrets Manager access policies to include environment path

### Phase 3: Frontend Infrastructure

- [x] **Module 17: S3 Buckets** (`modules/17-s3`) ✅ COMPLETED

  - [x] Frontend hosting bucket (with OAI policy)
  - [x] Versioning optional (disabled for dev cost optimization)
  - [x] Lifecycle policies applied

- [x] **Module 26: S3 Artifacts Bucket** (in `modules/26-codepipeline`) ✅ IMPLEMENTED

  - [x] CodePipeline artifacts bucket
  - [x] Versioning enabled
  - [x] Encryption enabled (AES256)
  - [x] Lifecycle policy (7-day retention)

- [ ] **Module 05: Route 53** (`modules/05-route53`)

  - [ ] Hosted zone: `typerush.com` (or use default CloudFront domain for dev)
  - [ ] A record: `typerush.com` → CloudFront (frontend)
  - [ ] A record: `api.typerush.com` → CloudFront (API)
  - [ ] Health checks optional (dev - basic monitoring sufficient)

- [ ] **Module 06: ACM Certificates** (`modules/06-acm`)

  - [ ] Certificate for `*.typerush.com`
  - [ ] DNS validation via Route 53
  - [ ] Certificate for CloudFront (us-east-1)
  - [ ] Certificate for ALB (ap-southeast-1)

- [ ] **Module 07: CloudFront** (`modules/07-cloudfront`)

  - [ ] Distribution for frontend (S3 origin)
  - [ ] Distribution for API (API Gateway origin)
  - [ ] Custom SSL certificate (or use default CloudFront SSL for dev)
  - [ ] Basic cache behaviors (static vs dynamic)
  - [ ] Origin failover optional (dev - single origin sufficient)
  - [ ] Geo-restriction optional (dev)

- [ ] **Module 08: WAF** (`modules/08-waf`)
  - [ ] Web ACL attached to CloudFront
  - [ ] Rate limiting rules (5000 req/5min per IP - dev)
  - [ ] AWS Managed Core Rule Set only (dev - minimal protection)
  - [ ] Advanced rules optional (SQL injection, XSS, bot detection - add for prod)

### Phase 4: Authentication & API Layer

- [ ] **Module 09: Cognito** (`modules/09-cognito`)

  - [ ] User Pool: email/password auth
  - [ ] Password policy (min 8 chars - basic dev policy)
  - [ ] MFA disabled (dev - enable for prod)
  - [ ] Custom attributes (playerLevel, totalMatches)
  - [ ] Lambda triggers optional (dev - add if needed)
  - [ ] Identity Pool optional (dev)
  - [ ] App client for frontend integration

- [ ] **Module 10: API Gateway** (`modules/10-api-gateway`)
  - [ ] **HTTP API Gateway**:
    - [ ] Cognito authorizer integration
    - [ ] VPC Link to internal ALB for `/api/game/*`
    - [ ] Direct Lambda integration for `/api/record/*` and `/api/text/*`
    - [ ] CORS configuration
    - [ ] Throttling limits (1000 req/sec burst, 500 steady - dev)
    - [ ] CloudWatch logging (errors only for dev cost optimization)
  - [ ] **WebSocket API Gateway**:
    - [ ] Cognito authorizer optional (dev - can test without auth)
    - [ ] **VPC Link to internal ALB** (routes to Game Service ECS)
    - [ ] Routes: $connect, $disconnect, $default (all handled by Game Service)
    - [ ] Connection management (handled by API Gateway + Game Service)
    - [ ] CloudWatch logging (errors only for dev)

### Phase 5: Load Balancing & Compute

- [ ] **Module 10a: VPC Link** (`modules/10a-vpc-link`)

  - [ ] VPC Link for HTTP API Gateway
  - [ ] Target: Internal ALB in private subnet (single AZ - dev)
  - [ ] Security group for VPC Link ENIs
  - [ ] Single-AZ deployment (dev cost optimization)

- [ ] **Module 11: Internal Application Load Balancer** (`modules/11-alb`)
  - [ ] **Internal ALB** in private subnet (not internet-facing, single AZ - dev)
  - [ ] HTTP listener only (port 80) for VPC Link integration (dev - HTTPS optional)
  - [ ] Target Group:
    - [ ] `typerush-game-tg` (port 3000, targets ECS tasks)
  - [ ] Health check path: `/health`
  - [ ] Access logs optional (dev - enable if debugging needed)
  - [ ] Deregistration delay: 30 seconds

### Phase 6: Data Layer

- [x] **Module 06: RDS PostgreSQL** (`modules/06-rds`) ✅ **COMPLETED**

  - [x] DB Subnet Group (database subnet - single AZ for dev)
  - [x] Record Service DB (single instance):
    - [x] Engine: PostgreSQL 17
    - [x] Instance: db.t3.micro (dev only - minimal cost)
    - [x] Single-AZ deployment (dev cost optimization)
    - [x] Storage: 20GB GP3 (no autoscaling for dev)
    - [x] Automated backups: 1 day retention (dev minimum)
    - [x] Encryption at rest: enabled
    - [x] Performance Insights: disabled (dev - enable if debugging)
    - [x] Database name: `typerush_records`
  - [x] Parameter Groups optional (dev - use defaults)
  - [x] Option Groups optional
  - [x] Read replicas not needed (dev)

- [x] **Module 09: DynamoDB** (`modules/09-dynamodb`) ✅ **COMPLETED**

  - [x] Table: `typerush-texts`
    - [x] Partition Key: `text_id` (String)
    - [x] GSI 1: `difficulty-language-index` (difficulty + language)
    - [x] GSI 2: `category-created-index` (category + created_at)
    - [x] Billing: On-demand (dev - pay per request)
    - [x] Encryption: AWS managed key
    - [x] Point-in-time recovery: disabled (dev - enable for prod)
    - [x] TTL attribute: `expires_at` (auto-delete AI texts after 90 days)
    - [x] Deletion protection: disabled (dev)

- [x] **Module 08: ElastiCache** (`modules/08-elasticache`) ✅ **COMPLETED**

  - [x] ElastiCache Subnet Group (elasticache subnet in single AZ)
  - [x] Redis Cluster: `typerush-game-cache`
    - [x] Engine: Redis 7.x
    - [x] Node type: cache.t4g.micro (ARM-based, cost-optimized)
    - [x] Cluster mode: Disabled (single node for dev)
    - [x] Multi-AZ: Disabled (dev only)
    - [x] Automatic backups: Disabled (dev - ephemeral cache)
    - [x] Encryption at rest: Enabled
    - [x] Encryption in transit: Enabled (TLS)
    - [x] Auth token: Enabled (password authentication)
    - [x] Port: 6379 (default Redis)
  - [x] Parameter Group (custom Redis settings if needed)
  - [x] Security group: Allow port 6379 from ECS SG only

- [x] **Module 04: Secrets Manager** (`modules/04-secrets-manager`) ✅ **COMPLETED**

  - [x] Secret: `typerush/dev/record-db/credentials` (username, password, host, port, database)
  - [x] Secret: `typerush/dev/elasticache/auth-token` (Redis authentication)
  - [x] Automatic rotation: disabled (dev - enable for prod)
  - [x] Random password generation for RDS (32 chars) and Redis (64 chars)
  - [x] IAM policies updated for secret access

- [x] **Module 05: VPC Endpoints** (`modules/05-vpc-endpoints`) ✅ **COMPLETED**
  - [x] **Interface Endpoints** (required for dev - 4 endpoints @ $7.20/month each):
    - [x] Secrets Manager endpoint (com.amazonaws.ap-southeast-1.secretsmanager)
    - [x] Bedrock Runtime endpoint (com.amazonaws.ap-southeast-1.bedrock-runtime)
    - [x] ECR API endpoint (com.amazonaws.ap-southeast-1.ecr.api)
    - [x] ECR Docker endpoint (com.amazonaws.ap-southeast-1.ecr.dkr)
    - [x] Private DNS enabled for each endpoint
    - [x] Security group: Allow 443 from ECS SG + Lambda SG
    - [x] Subnet associations: Private subnet (single AZ - dev)
    - [x] Total cost: 4 × $7.20 = $28.80/month
  - [x] **Gateway Endpoints** (free - always include):
    - [x] S3 endpoint (com.amazonaws.ap-southeast-1.s3)
    - [x] DynamoDB endpoint (com.amazonaws.ap-southeast-1.dynamodb)
    - [x] Route table associations: Private, database, and cache route tables
  - [x] **Skipped for Dev Cost Optimization**:
    - [x] CloudWatch Logs endpoint (use NAT Gateway instead - saves $7.20/month)

### Phase 7: Container Registry & Compute

- [x] **Module 10: ECR** (`modules/10-ecr`) ✅ **IMPLEMENTED (Not Applied)**

  - [x] Repository: `typerush/game-service`
  - [x] Repository: `typerush/record-service` (for Lambda container deployment)
  - [x] Image scanning: enabled on push (vulnerability detection)
  - [x] Lifecycle policy: keep last 10 images, expire untagged after 7 days
  - [x] Cross-region replication: disabled (dev)
  - [x] Immutable image tags: optional (dev - MUTABLE for flexibility)
  - **Note**: Terraform code written and validated, NOT yet applied to AWS

- [x] **Module 12: Internal ALB** (`modules/12-alb`) ✅ **IMPLEMENTED (Not Applied)**

  - [x] Internal ALB in private subnet (not internet-facing)
  - [x] Target Group for Game Service (port 3000, IP targets for Fargate)
  - [x] HTTP Listener on port 80
  - [x] Health check: `/health` endpoint
  - [x] CloudWatch alarms: Unhealthy targets, high response time, 5XX errors
  - [x] Deregistration delay: 30 seconds
  - [x] Stickiness: Disabled (stateless, session in Redis)
  - **Note**: Terraform code written and validated, NOT yet applied to AWS

- [x] **Module 11: ECS** (`modules/11-ecs`) ✅ **IMPLEMENTED (Not Applied)**

  - [x] ECS Cluster: `typerush-dev-ecs-cluster`
  - [x] Capacity providers: FARGATE only (dev - no SPOT for simplicity)
  - [x] Task Definition: Game Service
    - [x] Image: ECR URI from module 10
    - [x] CPU: 256, Memory: 512 (dev minimal - 0.25 vCPU, 0.5GB)
    - [x] Port mappings: 3000
    - [x] Environment variables (Redis endpoint)
    - [x] Secrets from Secrets Manager (Redis auth token)
    - [x] Health check: curl localhost:3000/health
    - [x] Log configuration (CloudWatch via NAT Gateway)
  - [x] ECS Service:
    - [x] Desired count: 1 (initial)
    - [x] Min: 1 (cannot scale to 0 with ALB)
    - [x] Max: 2 (basic auto-scaling for dev)
    - [x] Load balancer integration (internal ALB target group)
    - [x] Service discovery: disabled (dev)
    - [x] Auto-scaling policy: Target tracking on CPU (> 70%)
    - [x] Circuit breaker: enabled with rollback
    - [x] ECS Exec: enabled for debugging
  - **Note**: Terraform code written and validated, NOT yet applied to AWS
    - [ ] Deployment: rolling update
    - [ ] Circuit breaker: enabled
    - [ ] Health check grace period: 60 seconds
  - [ ] Task Auto-scaling:
    - [ ] Scale up: CPU > 70% for 2 minutes → add 1 task
    - [ ] Scale down: CPU < 30% for 5 minutes → remove to min 1

- [ ] **Module 18: Lambda** (`modules/18-lambda`)
  - [ ] Function: `typerush-record-api` (NestJS)
    - [ ] Runtime: Node.js 20
    - [ ] VPC configuration (private subnet for RDS access - single AZ dev)
    - [ ] Environment variables + Secrets Manager integration
    - [ ] Reserved concurrency: 10 (dev - minimal)
    - [ ] Provisioned concurrency: 0 (dev - cold starts acceptable)
    - [ ] Memory: 512 MB
    - [ ] Timeout: 30 seconds
    - [ ] API Gateway HTTP API integration (direct invocation)
    - [ ] Invokable by Game Service ECS (for saving match results)
  - [ ] Function: `typerush-text-generator` (FastAPI)
    - [ ] Runtime: Python 3.12
    - [ ] VPC configuration (private subnet for Bedrock/DynamoDB - single AZ dev)
    - [ ] Environment variables + Secrets Manager integration
    - [ ] Reserved concurrency: 5 (dev - minimal)
    - [ ] Provisioned concurrency: 0 (dev - cold starts acceptable)
    - [ ] Memory: 512 MB (dev - reduce if possible)
    - [ ] Timeout: 60 seconds
    - [ ] API Gateway HTTP API integration (direct invocation)
    - [ ] Invokable by Game Service ECS (for fetching in-game texts)
  - [ ] Lambda layers optional (dev - inline dependencies if small)

### Phase 8: CI/CD Pipeline

- [ ] **Module 19: CodeBuild** (`modules/19-codebuild`)

  - [ ] Build Project: `typerush-game-service-build`
    - [ ] Source: GitLab webhook
    - [ ] Environment: linux.small (dev - minimal compute)
    - [ ] Buildspec: builds Docker image, pushes to ECR
    - [ ] Artifacts: ECS task definition
    - [ ] Service role with ECR push permissions
    - [ ] Note: No migrations needed (Game Service doesn't use RDS)
  - [ ] Build Project: `typerush-record-service-build`
    - [ ] Source: GitLab webhook
    - [ ] Environment: Node.js 20
    - [ ] Buildspec: builds Lambda package (zip)
    - [ ] Artifacts: Lambda deployment package to S3
  - [ ] Build Project: `typerush-record-service-migrate`
    - [ ] Source: GitLab (same as build)
    - [ ] Environment: Node.js 20 with VPC access
    - [ ] VPC Configuration: Private subnet, RDS security group
    - [ ] Buildspec: runs Prisma migrations (`npx prisma migrate deploy`)
    - [ ] Secrets: Record DB credentials from Secrets Manager
  - [ ] Build Project: `typerush-text-service-build`
    - [ ] Source: GitLab webhook
    - [ ] Environment: Python 3.12
    - [ ] Buildspec: builds Lambda package (zip with dependencies)
    - [ ] Artifacts: Lambda deployment package to S3
  - [ ] Build Project: `typerush-frontend-build`
    - [ ] Static site build and S3 deployment

- [x] **Module 26: CodePipeline** (`modules/26-codepipeline`) ✅ IMPLEMENTED
  - [x] Pipeline: `typerush-game-service-pipeline`
    - [x] Stage 1: Source (GitLab webhook)
    - [x] Stage 2: Build (CodeBuild - Docker image, push to ECR)
    - [x] Stage 3: Deploy (ECS rolling update with new task definition)
    - [x] Note: No migration stage (Game Service uses ElastiCache only)
  - [x] Pipeline: `typerush-record-service-pipeline`
    - [x] Stage 1: Source (GitLab webhook)
    - [x] Stage 2: Build (CodeBuild - Lambda package to S3)
    - [x] Stage 3: Migrate (CodeBuild - run Prisma migrations)
    - [x] Stage 4: Deploy (Lambda function update)
  - [x] Pipeline: `typerush-text-service-pipeline`
    - [x] Stage 1: Source (GitLab webhook)
    - [x] Stage 2: Build (CodeBuild - Lambda package to S3)
    - [x] Stage 3: Deploy (Lambda function update)
  - [x] Pipeline: `typerush-frontend-pipeline`
    - [x] Stage 1: Source (GitLab webhook)
    - [x] Stage 2: Build (CodeBuild - npm build)
    - [x] Stage 3: Deploy (S3 sync)
  - [x] S3 bucket for artifacts with lifecycle policy (7 days)
  - [x] SNS notifications optional (disabled by default)

### Phase 9: Observability & Monitoring

- [ ] **Module 21: CloudWatch** (`modules/21-cloudwatch`)

  - [ ] Log Groups:
    - [ ] `/ecs/typerush-game-service`
    - [ ] `/aws/lambda/typerush-*`
    - [ ] `/aws/codebuild/typerush-*` (optional)
    - [ ] VPC Flow Logs optional (dev)
  - [ ] Log retention: 7 days (dev - minimal cost)
  - [ ] Metric Filters: optional (dev - add if debugging needed)
  - [ ] CloudWatch Dashboard: optional (dev - use metrics explorer instead)
  - [ ] CloudWatch Alarms (minimal for dev):
    - [ ] ECS service unhealthy (critical)
    - [ ] RDS connections > 80% max
    - [ ] ElastiCache CPU > 75%
    - [ ] ElastiCache memory > 80%
    - [ ] Lambda errors > 10 in 5 minutes
    - [ ] NAT Gateway packet drop count > 0

- [ ] **Module 22: SNS** (`modules/22-sns`) - Optional for dev

  - [ ] Topic: `typerush-dev-alerts` (single topic for dev)
  - [ ] Email subscription only (no SMS for dev)
  - [ ] CloudWatch Alarm actions

- [ ] **Module 23: EventBridge** (`modules/23-eventbridge`) - Optional for dev
  - [ ] Skip for initial dev setup
  - [ ] Add later if scheduled tasks needed (text generation, leaderboards)

### Phase 10: Additional Enhancements - Optional for dev

- [ ] **Bastion Host** (optional - use SSM Session Manager instead for dev)
- [ ] **AWS Backup** (skip for dev - manual snapshots if needed)
- [ ] **AWS Config** (skip for dev - not cost-effective)
- [ ] **GuardDuty** (skip for dev - enable for prod)
- [ ] **Systems Manager Parameter Store** (optional - use Secrets Manager)
- [ ] **X-Ray** (optional - enable if debugging distributed issues)
- [ ] **ElastiCache Redis** (skip for dev - add for prod if needed)

## 🎯 Success Criteria

### Functional Requirements

- [ ] Frontend accessible via `https://typerush.com`
- [ ] API accessible via `https://api.typerush.com`
- [ ] WebSocket accessible via `wss://ws.typerush.com`
- [ ] User registration and login via Cognito works
- [ ] HTTP API endpoints respond through CloudFront → API Gateway → VPC Link → Internal ALB (Game Service)
- [ ] HTTP API endpoints respond through CloudFront → API Gateway → Lambda (Record & Text Services)
- [ ] WebSocket connections work via API Gateway WebSocket → VPC Link → Internal ALB → Game Service ECS
- [ ] Game Service handles WebSocket connections for real-time gameplay (score streaming, matching)
- [ ] Game Service can read/write to ElastiCache for game session state
- [ ] Game Service does NOT access RDS (stateless, ElastiCache only)
- [ ] Game Service can call Text Service Lambda to fetch in-game texts
- [ ] Game Service can call Record Service Lambda to save match results
- [ ] Record Service can read/write to Record DB via RDS (from Lambda)
- [ ] All health check endpoints (`/health`) return 200 OK
- [ ] Database migrations run successfully via CodeBuild before deployments
- [ ] Text Service generates texts via Bedrock and stores in DynamoDB (from Lambda)
- [ ] All services retrieve secrets from Secrets Manager via VPC endpoints

### Security Requirements

- [ ] All traffic encrypted in transit (TLS 1.2+)
- [ ] No public IPs on private resources (ECS, RDS, Lambda, Internal ALB)
- [ ] Internal ALB only accessible via VPC Link (not internet-facing)
- [ ] All database credentials stored in Secrets Manager (retrieved via VPC endpoints)
- [ ] WAF rules blocking malicious traffic at CloudFront edge
- [ ] Security groups enforce least privilege (ECS, Lambda, RDS, VPC Endpoints)
- [ ] VPC Interface Endpoints used for Secrets Manager, Bedrock, CloudWatch
- [ ] VPC Gateway Endpoint used for DynamoDB (cost-free)
- [ ] IAM roles follow least privilege principle (no wildcard permissions)
- [ ] Encryption at rest for RDS, DynamoDB, S3

### Operational Requirements

- [ ] All services logging to CloudWatch
- [ ] CloudWatch alarms firing for error conditions
- [ ] SNS alerts received for critical issues
- [ ] ECS services auto-scaling based on load
- [ ] RDS automated backups working (7-day retention)
- [ ] DynamoDB point-in-time recovery enabled
- [ ] CodePipeline successfully deploying new code
- [ ] Health checks passing for all services
- [ ] Multi-AZ deployment verified (simulate AZ failure)

### Performance Requirements

- [ ] CloudFront cache hit ratio > 80% for static assets
- [ ] API Gateway latency < 100ms (excluding backend)
- [ ] ALB p99 latency < 500ms
- [ ] RDS query performance within acceptable limits
- [ ] DynamoDB read/write latency < 10ms
- [ ] No throttling errors under normal load
