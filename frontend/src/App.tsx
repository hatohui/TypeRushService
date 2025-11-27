import { useState, useEffect } from "react";
import "./App.css";

interface ServiceHealth {
  status: "healthy" | "unhealthy" | "degraded" | "checking";
  latency?: number;
  error?: string;
  checks?: Record<string, any>;
}

interface HealthStatus {
  status: string;
  timestamp: string;
  services: {
    game: ServiceHealth;
    record: ServiceHealth;
    text: ServiceHealth;
  };
}

// Environment variable or fallback to localhost
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api";

function App() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastCheck, setLastCheck] = useState<Date | null>(null);

  const fetchHealthStatus = async () => {
    try {
      setError(null);

      // Fetch health from each service individually
      const [gameRes, recordRes, textRes] = await Promise.allSettled([
        fetch(`${API_BASE_URL}/game/health`, {
          signal: AbortSignal.timeout(5000),
        }),
        fetch(`${API_BASE_URL}/record/health`, {
          signal: AbortSignal.timeout(5000),
        }),
        fetch(`${API_BASE_URL}/text/health`, {
          signal: AbortSignal.timeout(5000),
        }),
      ]);

      const gameHealth: ServiceHealth =
        gameRes.status === "fulfilled" && gameRes.value.ok
          ? await gameRes.value.json()
          : { status: "unhealthy", error: "Service unavailable" };

      const recordHealth: ServiceHealth =
        recordRes.status === "fulfilled" && recordRes.value.ok
          ? await recordRes.value.json()
          : { status: "unhealthy", error: "Service unavailable" };

      const textHealth: ServiceHealth =
        textRes.status === "fulfilled" && textRes.value.ok
          ? await textRes.value.json()
          : { status: "unhealthy", error: "Service unavailable" };

      const overallHealthy = [gameHealth, recordHealth, textHealth].every(
        (h) => h.status === "healthy"
      );

      setHealth({
        status: overallHealthy ? "healthy" : "degraded",
        timestamp: new Date().toISOString(),
        services: {
          game: gameHealth,
          record: recordHealth,
          text: textHealth,
        },
      });

      setLastCheck(new Date());
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch health status"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealthStatus();
    const interval = setInterval(fetchHealthStatus, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const getStatusBadge = (status: string) => {
    const colors = {
      healthy: "#10b981",
      unhealthy: "#ef4444",
      degraded: "#f59e0b",
      checking: "#6b7280",
    };
    return (
      <span
        style={{
          background: colors[status as keyof typeof colors] || "#6b7280",
          color: "white",
          padding: "0.25rem 0.75rem",
          borderRadius: "0.5rem",
          fontSize: "0.875rem",
          fontWeight: "600",
          textTransform: "uppercase",
        }}
      >
        {status}
      </span>
    );
  };

  const getLatencyColor = (latency: number | undefined) => {
    if (!latency) return "#6b7280";
    if (latency < 100) return "#10b981";
    if (latency < 300) return "#f59e0b";
    return "#ef4444";
  };

  if (loading && !health) {
    return (
      <div className="container">
        <div className="header">
          <h1>🚀 TypeRush Health Dashboard</h1>
          <p>Loading health status...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="header">
        <h1>🚀 TypeRush Health Dashboard</h1>
        <div className="header-info">
          <div>Overall Status: {health && getStatusBadge(health.status)}</div>
          {lastCheck && (
            <div style={{ fontSize: "0.875rem", color: "#e5e7eb" }}>
              Last checked: {lastCheck.toLocaleTimeString()}
            </div>
          )}
          <button onClick={fetchHealthStatus} className="refresh-btn">
            🔄 Refresh
          </button>
        </div>
      </div>

      {error && <div className="error-banner">⚠️ {error}</div>}

      {health && (
        <>
          <div className="architecture-diagram">
            <pre style={{ fontSize: "0.75rem", lineHeight: "1.4" }}>
              {`
┌─────────────────┐
│   Frontend      │ ${health.status === "healthy" ? "✓" : "✗"}
└────────┬────────┘
         │
    CloudFront
         │
    API Gateway
         │
         ├──────────────┬──────────────┬──────────────┐
         │              │              │              │
   ┌─────▼──────┐ ┌────▼─────┐  ┌────▼─────┐  ┌─────▼──────┐
   │ Game Svc   │ │  Record  │  │   Text   │  │    ALB     │
   │   (ECS)    │ │ (Lambda) │  │ (Lambda) │  │  Health    │
   │     ${health.services.game.status === "healthy" ? "✓" : "✗"}      │ │    ${
                health.services.record.status === "healthy" ? "✓" : "✗"
              }     │  │    ${
                health.services.text.status === "healthy" ? "✓" : "✗"
              }     │  │     ✓      │
   └─────┬──────┘ └────┬─────┘  └────┬─────┘  └────────────┘
         │            │              │
    ElastiCache   PostgreSQL    DynamoDB
       Redis          RDS        + Bedrock
`}
            </pre>
          </div>

          <div className="services-grid">
            {/* Game Service */}
            <div className="service-card">
              <div className="service-header">
                <h2>🎮 Game Service (ECS)</h2>
                {getStatusBadge(health.services.game.status)}
              </div>
              <div className="service-body">
                <div className="service-info">
                  <span className="label">Type:</span>
                  <span>ECS Fargate Container</span>
                </div>
                <div className="service-info">
                  <span className="label">Tech Stack:</span>
                  <span>Node.js + Express</span>
                </div>
                {health.services.game.latency !== undefined && (
                  <div className="service-info">
                    <span className="label">Latency:</span>
                    <span
                      style={{
                        color: getLatencyColor(health.services.game.latency),
                      }}
                    >
                      {health.services.game.latency}ms
                    </span>
                  </div>
                )}
                {health.services.game.checks && (
                  <div className="checks">
                    <h3>Dependencies:</h3>
                    {Object.entries(health.services.game.checks).map(
                      ([key, value]: [string, any]) => (
                        <div key={key} className="check-item">
                          <span>{key}:</span>
                          <span
                            style={{
                              color:
                                value.status === "healthy"
                                  ? "#10b981"
                                  : "#ef4444",
                            }}
                          >
                            {value.status}{" "}
                            {value.latency && `(${value.latency}ms)`}
                          </span>
                        </div>
                      )
                    )}
                  </div>
                )}
                {health.services.game.error && (
                  <div className="error-text">
                    Error: {health.services.game.error}
                  </div>
                )}
              </div>
            </div>

            {/* Record Service */}
            <div className="service-card">
              <div className="service-header">
                <h2>📊 Record Service (Lambda)</h2>
                {getStatusBadge(health.services.record.status)}
              </div>
              <div className="service-body">
                <div className="service-info">
                  <span className="label">Type:</span>
                  <span>AWS Lambda Function</span>
                </div>
                <div className="service-info">
                  <span className="label">Tech Stack:</span>
                  <span>NestJS + Prisma</span>
                </div>
                {health.services.record.latency !== undefined && (
                  <div className="service-info">
                    <span className="label">Latency:</span>
                    <span
                      style={{
                        color: getLatencyColor(health.services.record.latency),
                      }}
                    >
                      {health.services.record.latency}ms
                    </span>
                  </div>
                )}
                {health.services.record.checks && (
                  <div className="checks">
                    <h3>Dependencies:</h3>
                    {Object.entries(health.services.record.checks).map(
                      ([key, value]: [string, any]) => (
                        <div key={key} className="check-item">
                          <span>{key}:</span>
                          <span
                            style={{
                              color:
                                value.status === "healthy"
                                  ? "#10b981"
                                  : "#ef4444",
                            }}
                          >
                            {value.status}{" "}
                            {value.latency && `(${value.latency}ms)`}
                          </span>
                        </div>
                      )
                    )}
                  </div>
                )}
                {health.services.record.error && (
                  <div className="error-text">
                    Error: {health.services.record.error}
                  </div>
                )}
              </div>
            </div>

            {/* Text Service */}
            <div className="service-card">
              <div className="service-header">
                <h2>📝 Text Service (Lambda)</h2>
                {getStatusBadge(health.services.text.status)}
              </div>
              <div className="service-body">
                <div className="service-info">
                  <span className="label">Type:</span>
                  <span>AWS Lambda Function</span>
                </div>
                <div className="service-info">
                  <span className="label">Tech Stack:</span>
                  <span>Python + FastAPI</span>
                </div>
                {health.services.text.latency !== undefined && (
                  <div className="service-info">
                    <span className="label">Latency:</span>
                    <span
                      style={{
                        color: getLatencyColor(health.services.text.latency),
                      }}
                    >
                      {health.services.text.latency}ms
                    </span>
                  </div>
                )}
                {health.services.text.checks && (
                  <div className="checks">
                    <h3>Dependencies:</h3>
                    {Object.entries(health.services.text.checks).map(
                      ([key, value]: [string, any]) => (
                        <div key={key} className="check-item">
                          <span>{key}:</span>
                          <span
                            style={{
                              color:
                                value.status === "healthy"
                                  ? "#10b981"
                                  : "#ef4444",
                            }}
                          >
                            {value.status}{" "}
                            {value.latency && `(${value.latency}ms)`}
                          </span>
                        </div>
                      )
                    )}
                  </div>
                )}
                {health.services.text.error && (
                  <div className="error-text">
                    Error: {health.services.text.error}
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="footer">
            <p>Auto-refreshes every 30 seconds</p>
            <p style={{ fontSize: "0.75rem", marginTop: "0.5rem" }}>
              Timestamp: {new Date(health.timestamp).toLocaleString()}
            </p>
          </div>
        </>
      )}
    </div>
  );
}

export default App;
