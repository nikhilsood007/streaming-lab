# Live Streaming Ingest Lab

A complete open-source lab environment for practicing live streaming ingest scheduling and monitoring using Docker Compose. This lab provides hands-on experience with FFmpeg streaming, RTMP servers, Prometheus metrics collection, Grafana visualization, and Node-RED automation.

## Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   FFmpeg    │───▶│  MediaMTX   │───▶│ Prometheus  │───▶│   Grafana   │
│ (Publisher) │    │(RTMP Server)│    │ (Metrics)   │    │(Dashboard)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       ▲                   │                    │               │
       │                   ▼                    │               ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Node-RED   │    │ HLS/WebRTC  │    │AlertManager │    │  Dashboard  │
│(Scheduler)  │    │ (Viewers)   │    │  (Alerts)   │    │  (3000)     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Why This Stack?

- **MediaMTX**: Modern, lightweight streaming server with built-in Prometheus metrics
- **Prometheus**: Industry-standard metrics collection and alerting
- **Grafana**: Powerful visualization with pre-built dashboards
- **Node-RED**: Visual, low-code scheduler perfect for automation practice
- **Docker Compose**: Simplified deployment and teardown for lab environments

## Quick Start

### Prerequisites

- Docker and Docker Compose v2.0+
- FFmpeg installed on host system
- At least 4GB RAM available
- Ports 1935, 3000, 9090, 1880, 9093 available

### First Run

1. **Clone and Setup**:
```bash
git clone <this-repo>
cd streaming-lab
chmod +x scripts/*.sh
mkdir -p media logs
```

2. **Start Services**:
```bash
# Default profile (MediaMTX)
docker compose up -d

# Alternative: SRS profile
docker compose --profile srs up -d
```

3. **Access Services**:
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- Node-RED: http://localhost:1880
- AlertManager: http://localhost:9093

4. **Test Stream**:
```bash
# Start a 5-minute test pattern
./scripts/start_stream.sh 300 live/test testsrc

# Check Grafana dashboard for metrics
# Stop stream
./scripts/stop_stream.sh
```

## Detailed Setup

### Service Configuration

#### MediaMTX (Default)
- **RTMP Port**: 1935
- **Metrics Port**: 9998
- **API Port**: 9997
- **HLS Port**: 8888
- **WebRTC Port**: 8889

#### SRS (Alternative Profile)
- **RTMP Port**: 1935
- **HTTP Port**: 8080
- **API Port**: 1985
- **Metrics Port**: 9972

#### Prometheus
- **Web UI**: 9090
- **Scrape Interval**: 15s
- **Targets**: MediaMTX/SRS, Node-RED, AlertManager

#### Grafana
- **Web UI**: 3000
- **Username**: admin
- **Password**: admin (change on first login)
- **Auto-provisioned**: Prometheus datasource + streaming dashboard

### Directory Structure

```
streaming-lab/
├── docker-compose.yml          # Main compose file
├── config/                     # Configuration files
│   ├── mediamtx.yml           # MediaMTX server config
│   ├── srs.conf               # SRS server config (alternative)
│   ├── prometheus.yml         # Prometheus scrape config
│   ├── alerts.yml             # Alert rules
│   ├── alertmanager.yml       # Alert manager config
│   └── grafana/               # Grafana provisioning
│       ├── provisioning/
│       │   ├── datasources/
│       │   │   └── prometheus.yml
│       │   └── dashboards/
│       │       └── dashboards.yml
│       └── dashboards/
│           └── streaming.json
├── scripts/                   # Shell scripts
│   ├── start_stream.sh       # Start FFmpeg streams
│   └── stop_stream.sh        # Stop streams gracefully
├── nodered/                  # Node-RED flows
│   └── flows.json           # Pre-built scheduling flows
├── media/                    # Media files directory
└── logs/                     # Log files
```

## Usage Guide

### Starting Streams

#### Manual Commands
```bash
# Test pattern for 5 minutes
./scripts/start_stream.sh 300 live/test testsrc

# Stream from video file continuously
./scripts/start_stream.sh 0 live/stream sample.mp4

# Webcam stream for 1 minute
./scripts/start_stream.sh 60 live/webcam webcam

# Custom settings
BITRATE=2000k RESOLUTION=1920x1080 ./scripts/start_stream.sh 600 live/hd input.mp4
```

#### Node-RED Scheduling
1. Access Node-RED at http://localhost:1880
2. Import the provided flow from `nodered/flows.json`
3. Deploy the flow
4. Use inject nodes for manual testing or configure cron schedules

**Default Schedules**:
- **9:00 AM**: Start test pattern (1 hour)
- **6:00 PM**: Start file stream (1 hour)
- **10:00 AM & 7:00 PM**: Stop all streams

### Monitoring in Grafana

1. **Access Dashboard**: 
   - URL: http://localhost:3000
   - Login: admin/admin
   - Dashboard: "Streaming Lab Dashboard"

2. **Key Metrics**:
   - Active Publishers/Readers
   - Ingest/Output Throughput
   - Server Health Status
   - Stream Status Gauges

3. **Alert Examples**:
   - No active publishers for 5+ minutes
   - High reader count (>100 concurrent)
   - Server downtime alerts

### Switching Between MediaMTX and SRS

#### Using MediaMTX (Default)
```bash
docker compose down
docker compose up -d
```

#### Using SRS (Alternative)
```bash
docker compose down
docker compose --profile srs up -d
```

**Key Differences**:
- **MediaMTX**: Simpler config, built-in metrics
- **SRS**: More features, separate Prometheus exporter
- Both support RTMP ingest and HLS/WebRTC output
- Grafana dashboard works with both (metrics may differ)

## Advanced Configuration

### Adding Custom Media Files

1. Place video files in `./media/` directory
2. Reference in scripts as just the filename:
```bash
./scripts/start_stream.sh 0 live/movie movie.mp4
```

### Customizing Stream Parameters

Environment variables:
```bash
export RTMP_URL=rtmp://remote-server:1935
export BITRATE=3000k
export RESOLUTION=1920x1080
export FPS=60
./scripts/start_stream.sh 300 live/highquality testsrc
```

### Adding Datadog Integration

#### Option 1: Grafana Cloud/Enterprise (Official Plugin)
1. Install Datadog datasource plugin
2. Add datasource with API keys:
```yaml
# In grafana/provisioning/datasources/datadog.yml
- name: Datadog
  type: datadog
  url: https://api.datadoghq.com
  jsonData:
    site: datadoghq.com
  secureJsonData:
    apiKey: YOUR_API_KEY
    appKey: YOUR_APP_KEY
```

#### Option 2: Grafana OSS (JSON API Plugin)
1. Install JSON datasource plugin:
```bash
docker compose exec grafana grafana-cli plugins install marcusolsson-json-datasource
docker compose restart grafana
```

2. Add JSON datasource pointing to Datadog API:
```yaml
- name: Datadog-API
  type: marcusolsson-json-datasource
  url: https://api.datadoghq.com/api/v1
  jsonData:
    queryParams: 'api_key=YOUR_API_KEY&application_key=YOUR_APP_KEY'
```

3. Create panels with Datadog queries:
```json
{
  "query": "metrics/query?from={{__from}}&to={{__to}}&query=avg:system.cpu.user{*}",
  "parser": "$.series[*].pointlist[*]",
  "fields": [
    {"name": "time", "jsonPath": "$[0]"},
    {"name": "value", "jsonPath": "$[1]"}
  ]
}
```

### Custom Alert Rules

Add to `config/alerts.yml`:
```yaml
- alert: CustomStreamAlert
  expr: rate(mediamtx_bytes_received_total[5m]) < 1000
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Low ingest bitrate detected"
    description: "Ingest bitrate has been below 1KB/s for 2 minutes"
```

## Troubleshooting

### Common Issues

#### 1. FFmpeg Not Starting
```bash
# Check FFmpeg installation
ffmpeg -version

# Check logs
tail -f logs/stream_*.log

# Test RTMP connection
ffplay rtmp://localhost:1935/live/test
```

#### 2. No Metrics in Grafana
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check MediaMTX metrics
curl http://localhost:9998/metrics

# Restart services
docker compose restart prometheus grafana
```

#### 3. Permission Issues
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix directory permissions
sudo chown -R $USER:$USER logs/ media/
```

#### 4. Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep -E ":(1935|3000|9090|1880)"

# Modify ports in docker-compose.yml if needed
```

### Service Health Checks

```bash
# Check all services
docker compose ps

# View logs
docker compose logs mediamtx
docker compose logs prometheus
docker compose logs grafana

# Check metrics endpoints
curl http://localhost:9998/metrics  # MediaMTX
curl http://localhost:9972/metrics  # SRS
```

## Understanding the Data Flow

### 1. Stream Ingestion
```
FFmpeg → RTMP (port 1935) → MediaMTX/SRS → HLS/WebRTC output
```

### 2. Metrics Collection
```
MediaMTX/SRS → Prometheus metrics endpoint → Prometheus scraper → TSDB
```

### 3. Visualization
```
Prometheus TSDB → Grafana queries → Dashboard panels → Alerts
```

### 4. Automation
```
Node-RED cron → Shell exec → FFmpeg process → Stream metrics → Dashboard updates
```

## Extending the Lab

### Adding New Services

1. **Node Exporter** (system metrics):
```yaml
node-exporter:
  image: prom/node-exporter
  ports: ["9100:9100"]
```

2. **Redis** (for stream metadata):
```yaml
redis:
  image: redis:alpine
  ports: ["6379:6379"]
```

### Custom Dashboards

1. Export existing dashboard JSON
2. Modify panels and queries
3. Import via Grafana UI or provisioning

### Integration Testing

Create test scenarios in Node-RED:
- Load testing with multiple streams
- Failover testing
- Alert validation
- Performance benchmarking

## Production Considerations

### Security
- Change default passwords
- Enable HTTPS/TLS
- Restrict network access
- Use secrets management

### Scalability
- Add load balancing
- Use external Prometheus/Grafana
- Implement stream clustering
- Monitor resource usage

### Monitoring
- Set up proper alerting channels
- Monitor infrastructure metrics
- Implement log aggregation
- Create runbooks for incidents

## Learning Outcomes

After completing this lab, you'll understand:

1. **RTMP Streaming**: How to ingest live streams using FFmpeg and RTMP
2. **Metrics Collection**: How Prometheus scrapes and stores time-series data
3. **Visualization**: How to create effective monitoring dashboards
4. **Automation**: How to schedule and orchestrate streaming workflows
5. **Alerting**: How to set up meaningful alerts for streaming services
6. **Integration**: How to combine multiple monitoring tools in one dashboard

## Next Steps

- **Scale Up**: Deploy to Kubernetes with Helm charts
- **Add Features**: Implement stream transcoding, recording, CDN integration
- **Monitoring**: Add APM tools like Jaeger for distributed tracing
- **Automation**: Create more complex scheduling scenarios
- **Integration**: Connect to cloud streaming platforms

## Resources

### Documentation
- [MediaMTX Documentation](https://github.com/bluenviron/mediamtx)
- [SRS Documentation](https://ossrs.net/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node-RED Documentation](https://nodered.org/docs/)

### FFmpeg Resources
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [RTMP Streaming Guide](https://trac.ffmpeg.org/wiki/StreamingGuide)

### Best Practices
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)

---

**Happy Streaming!** 🎥📊

For support and contributions, please refer to the project repository.