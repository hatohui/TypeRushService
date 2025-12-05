# TypeRush Health Dashboard

A real-time health monitoring dashboard for the TypeRush microservices architecture.

## Features

- 🎮 **Game Service** monitoring (ECS Fargate)
- 📊 **Record Service** monitoring (Lambda + PostgreSQL)
- 📝 **Text Service** monitoring (Lambda + DynamoDB + Bedrock)
- 🔄 Auto-refresh every 30 seconds
- 📊 ASCII architecture diagram visualization
- ⚡ Latency tracking for all services
- 🚨 Dependency health checks (Redis, PostgreSQL, DynamoDB, Bedrock)

## Quick Start

### Local Development

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Configure environment:**

   ```bash
   cp .env.example .env
   # Edit .env and set VITE_API_BASE_URL to your API endpoints
   ```

3. **Start development server:**

   ```bash
   npm run dev
   ```

4. **Open browser:**
   Navigate to http://localhost:3000

### Production Build

```bash
npm run build
npm run preview
```

## Environment Variables

| Variable            | Description              | Example                        |
| ------------------- | ------------------------ | ------------------------------ |
| `VITE_API_BASE_URL` | Base URL for API Gateway | `https://api.typerush.com/api` |

## API Endpoints Expected

The dashboard expects these health endpoints to be available:

- `GET /api/game/health` - Game Service health
- `GET /api/record/health` - Record Service health
- `GET /api/text/health` - Text Service health

Each endpoint should return:

```json
{
  "status": "healthy" | "unhealthy",
  "service": "service-name",
  "timestamp": "2025-11-23T10:00:00.000Z",
  "checks": {
    "dependency-name": {
      "status": "healthy" | "unhealthy",
      "latency": 123
    }
  },
  "version": "1.0.0"
}
```

## Architecture

```
Frontend (React + Vite)
    ↓
API Gateway
    ↓
    ├─→ Game Service (ECS) → Redis
    ├─→ Record Service (Lambda) → PostgreSQL
    └─→ Text Service (Lambda) → DynamoDB + Bedrock
```

## Deployment

### To S3 + CloudFront

1. Build the project:

   ```bash
   npm run build
   ```

2. Upload `dist/` to S3 bucket:

   ```bash
   aws s3 sync dist/ s3://your-bucket-name --delete
   ```

3. Invalidate CloudFront cache:
   ```bash
   aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
   ```

## Development

- **Framework:** React 18 + TypeScript
- **Build Tool:** Vite
- **Styling:** Pure CSS (no framework dependencies)
- **State Management:** React Hooks (useState, useEffect)

## License

MIT
