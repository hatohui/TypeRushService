# Step 08: ElastiCache Redis Cluster

## Status: COMPLETED

## Completed: 2025-11-23

## Terraform Module: `modules/08-elasticache`

## Overview

Create a single-node ElastiCache Redis cluster for the Game Service to store real-time game session state. Configured for dev environment with AUTH token and encryption.

## Architecture Reference

From `architecture-diagram.md`:

- **Engine**: Redis 7.1 (latest)
- **Node Type**: cache.t4g.micro (ARM-based, cost-efficient)
- **Cost**: $12.41/month (single-node, on-demand)
- **Purpose**: Game session state, leaderboards, real-time data
- **Network**: Deployed in Cache Subnet (10.0.202.0/24)
- **Access**: Only Game Service ECS can connect

## Components to Implement

### 1. ElastiCache Subnet Group

- [ ] **Name**: `typerush-dev-redis-subnet-group`
- [ ] **Subnets**: Cache subnet (minimum 1 for single-node)
- [ ] **Purpose**: Define where Redis node can be placed
- [ ] **Note**: Multi-AZ requires multiple subnets in different AZs

### 2. Redis Replication Group (Single Node)

- [ ] **Replication Group ID**: `typerush-dev-redis`
- [ ] **Description**: "TypeRush game session cache"
- [ ] **Engine**: Redis
- [ ] **Engine Version**: 7.1 (latest stable)
- [ ] **Node Type**: cache.t4g.micro (2 vCPU, 0.5 GB RAM, ARM-based)
- [ ] **Number of Cache Clusters**: 1 (single-node for dev)
- [ ] **Port**: 6379 (Redis default)
- [ ] **Parameter Group**: default.redis7
- [ ] **Multi-AZ**: Disabled (automatic failover disabled)
- [ ] **Automatic Failover**: Disabled (requires 2+ nodes)

### 3. Authentication and Encryption

- [ ] **AUTH Token**: Retrieved from Secrets Manager
  - [ ] 64-character alphanumeric string
  - [ ] Generated using Terraform random_password
  - [ ] Stored in Secrets Manager
- [ ] **Transit Encryption**: Enabled (TLS/SSL)
- [ ] **At-Rest Encryption**: Enabled (default AWS key)
- [ ] **Auth Token Update Strategy**: SET (enforce immediately)

### 4. Network Configuration

- [ ] **Subnet Group**: Redis subnet group (cache subnet)
- [ ] **Security Group**: ElastiCache security group (only ECS access)
- [ ] **Publicly Accessible**: False

### 5. Backup and Maintenance

- [ ] **Snapshot Retention**: 0 days (no automatic snapshots for dev)
- [ ] **Snapshot Window**: N/A (snapshots disabled)
- [ ] **Maintenance Window**: sun:04:00-sun:05:00 (Singapore night)
- [ ] **Auto Minor Version Upgrade**: False (manual control in dev)
- [ ] **Final Snapshot**: Create manual snapshot before deletion

### 6. Performance and Monitoring

- [ ] **CloudWatch Logs**: Export slow logs (optional)
  - [ ] Enable: slow-log
  - [ ] Retention: 7 days
- [ ] **Log Delivery Configuration**: Optional for dev
- [ ] **Notification Topic**: SNS topic for alerts (optional)

## Redis Data Model

### Game Session State

```redis
# Session key pattern
game:session:{session_id} -> Hash
  - player_ids: [uuid1, uuid2, ...]
  - text_id: uuid
  - started_at: timestamp
  - status: "waiting|active|completed"
  - wpm_scores: {player_id: wpm}
  - accuracy_scores: {player_id: accuracy}

# Player progress
game:player:{session_id}:{player_id} -> String (JSON)
  - current_position: 150
  - correct_chars: 145
  - incorrect_chars: 5
  - last_update: timestamp

# Leaderboard (sorted set)
game:leaderboard:daily -> Sorted Set
  score: wpm, member: player_id

# Session expiry: 1 hour
```

## Implementation Details

### Secrets Manager Integration

```hcl
data "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = "typerush/elasticache/auth-token"
}

locals {
  redis_config = jsondecode(data.aws_secretsmanager_secret_version.redis_auth.secret_string)
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "TypeRush game session cache"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = var.elasticache_node_type

  num_cache_clusters = 1
  port               = 6379
  parameter_group_name = "default.redis7"

  # Authentication and Encryption
  auth_token                 = local.redis_config.auth_token
  auth_token_update_strategy = "SET"
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  # Network
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.elasticache_security_group_id]

  # Maintenance
  maintenance_window       = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = false

  # Backup
  snapshot_retention_limit = 0

  # Monitoring (optional)
  # log_delivery_configuration {
  #   destination      = aws_cloudwatch_log_group.redis_slow_log.name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "json"
  #   log_type         = "slow-log"
  # }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-redis"
      Purpose = "Game session state"
    }
  )
}
```

### Connection String for Game Service

```
redis://:{auth_token}@typerush-dev-redis.xxxxx.cache.amazonaws.com:6379?tls=true
```

## Module Structure

```
modules/13-elasticache/
├── main.tf       # Subnet group, replication group
├── variables.tf  # Node type, subnet IDs, security group ID
└── outputs.tf    # Primary endpoint, reader endpoint, port
```

## Dependencies

- **Required**: Module 01 (Networking) - Cache subnet
- **Required**: Module 02 (Security Groups) - ElastiCache security group
- **Required**: Module 14 (Secrets Manager) - Redis AUTH token

## Deployment

```powershell
# Deploy ElastiCache (takes ~10-15 minutes)
terraform apply -var-file="env\dev.tfvars.local" -target=module.elasticache
```

## Validation Commands

```powershell
# Check Redis cluster status
aws elasticache describe-replication-groups --replication-group-id typerush-dev-redis

# Get endpoint
$REDIS_ENDPOINT = terraform output -raw redis_primary_endpoint

# Test connection from ECS (requires Game Service deployed)
# Using redis-cli in Game Service container
aws ecs execute-command --cluster typerush-dev-ecs-cluster `
  --task <task-id> --container game-service `
  --command "redis-cli -h $REDIS_ENDPOINT -p 6379 -a <auth-token> --tls PING"

# Expected output: PONG
```

## Redis Commands for Testing

### Set Session Data

```bash
# Connect to Redis
redis-cli -h typerush-dev-redis.xxxxx.cache.amazonaws.com -p 6379 -a <auth-token> --tls

# Create session
HSET game:session:test-123 status "active" player_count 2 text_id "uuid-456"

# Set player progress
SET game:player:test-123:player1 '{"current_position":100,"wpm":45}'

# Add to leaderboard
ZADD game:leaderboard:daily 85 player1

# Get leaderboard top 10
ZREVRANGE game:leaderboard:daily 0 9 WITHSCORES

# Set expiry (1 hour)
EXPIRE game:session:test-123 3600
```

## Cost Impact

**$12.41/month**

- cache.t4g.micro: $0.017/hour = $12.24/month
- Data transfer: ~$0.10-$0.20/month (minimal, private subnet)
- Backup storage: $0 (no snapshots in dev)

**4-day demo**: ~$1.70/day × 4 = $6.80

## Performance Considerations

### Dev Environment

- **Expected Load**: 1-10 concurrent game sessions
- **Memory**: 0.5 GB sufficient for ~5,000 active sessions
- **Throughput**: Single-threaded, ~100,000 ops/sec

### Data Eviction Policy

- **maxmemory-policy**: allkeys-lru (evict least recently used)
- **maxmemory**: 80% of available memory (400 MB usable)

### Scaling for Production

```
Dev:       cache.t4g.micro   (0.5 GB)  → $12/mo
Staging:   cache.t4g.small   (1.5 GB)  → $25/mo
Prod:      cache.t4g.medium  (3.0 GB)  → $50/mo Multi-AZ with replica
```

## Security Considerations

### ✅ Network Isolation

```
Game Service ECS (private subnet)
    ↓ (via ECS Security Group)
ElastiCache Security Group (allows Redis:6379 from ECS SG only)
    ↓
Redis Node (cache subnet, no internet access)
```

### ✅ Encryption

- **At Rest**: AWS-managed key (free)
- **In Transit**: TLS 1.2+ enforced via transit_encryption_enabled
- **AUTH Token**: 64-char strong password from Secrets Manager

### ✅ Access Control

- **ECS IAM Role**: Can read AUTH token from Secrets Manager
- **Security Group**: Only ECS security group can reach Redis port
- **No Public Access**: Endpoint not accessible from internet
- **AUTH Required**: All commands require valid AUTH token

### ✅ Session Data Security

- **TTL**: All session keys expire after 1 hour
- **No PII**: Only game state, no personal information
- **Encryption**: All data encrypted at rest and in transit

## Monitoring and Alerting

### CloudWatch Metrics

- [ ] CPUUtilization > 75% for 5 minutes
- [ ] EngineCPUUtilization > 90% for 5 minutes
- [ ] DatabaseMemoryUsagePercentage > 85%
- [ ] CurrConnections > 50 (out of ~65,000 max)
- [ ] Evictions > 10 per minute (memory pressure)
- [ ] CacheMisses > CacheHits (inefficient caching)

### CloudWatch Logs (Optional)

- Slow logs (queries > 10ms)
- Engine logs (errors, warnings)

## Testing Plan

1. [ ] Deploy ElastiCache cluster
2. [ ] Verify cluster is "available" status
3. [ ] Test ECS can retrieve AUTH token from Secrets Manager
4. [ ] Test Game Service can connect to Redis
5. [ ] Test SET/GET operations with AUTH
6. [ ] Test TLS connection enforcement
7. [ ] Verify data persistence across container restarts
8. [ ] Test TTL expiration
9. [ ] Load test with 100+ concurrent sessions
10. [ ] Test manual snapshot creation

## Redis Client Libraries

### Node.js (Game Service)

```typescript
import { createClient } from "redis";

const client = createClient({
  url: `rediss://default:${authToken}@${redisEndpoint}:6379`,
  socket: {
    tls: true,
    rejectUnauthorized: true,
  },
});

await client.connect();
```

### Connection Pooling

- Use `ioredis` with cluster support (future-proof)
- Connection pool size: 10-20 connections
- Retry strategy: exponential backoff

## Rollback Plan

```powershell
# Create manual snapshot before deletion
aws elasticache create-snapshot `
  --replication-group-id typerush-dev-redis `
  --snapshot-name typerush-dev-redis-final-$(Get-Date -Format 'yyyyMMdd-HHmmss')

# Destroy ElastiCache
terraform destroy -target=module.elasticache

# Restore from snapshot if needed
aws elasticache create-replication-group `
  --replication-group-id typerush-dev-redis-restored `
  --replication-group-description "Restored from snapshot" `
  --snapshot-name typerush-dev-redis-final-20251123-120000
```

## Common Issues

### Issue: AUTH token mismatch

```
Error: NOAUTH Authentication required
Solution: Verify AUTH token in Secrets Manager matches cluster config
```

### Issue: Connection timeout

```
Error: ETIMEDOUT
Solution: Check security group allows ECS SG on port 6379
```

### Issue: TLS handshake failure

```
Error: SSL routines:ssl3_get_record:wrong version number
Solution: Ensure client uses rediss:// protocol (not redis://)
```

## Next Step

Proceed to [Step 09: DynamoDB Table](./09_dynamodb.md)
