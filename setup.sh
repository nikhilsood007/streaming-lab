#!/bin/bash

# Quick Setup Script for Streaming Lab
# Run this after cloning the repository

set -e

echo "=== Streaming Lab Setup ==="
echo "Setting up directory structure and permissions..."

# Create required directories
mkdir -p config/grafana/provisioning/datasources
mkdir -p config/grafana/provisioning/dashboards
mkdir -p config/grafana/dashboards
mkdir -p config/nodered
mkdir -p scripts
mkdir -p media
mkdir -p logs

# Move config files to proper locations
echo "Organizing configuration files..."

# MediaMTX config
if [ -f "config-mediamtx.yml" ]; then
    mv config-mediamtx.yml config/mediamtx.yml
fi

# SRS config
if [ -f "config-srs.conf" ]; then
    mv config-srs.conf config/srs.conf
fi

# Prometheus configs
if [ -f "config-prometheus.yml" ]; then
    mv config-prometheus.yml config/prometheus.yml
fi

if [ -f "config-alerts.yml" ]; then
    mv config-alerts.yml config/alerts.yml
fi

if [ -f "config-alertmanager.yml" ]; then
    mv config-alertmanager.yml config/alertmanager.yml
fi

# Grafana configs
if [ -f "grafana-datasources.yml" ]; then
    mv grafana-datasources.yml config/grafana/provisioning/datasources/prometheus.yml
fi

if [ -f "grafana-dashboards.yml" ]; then
    mv grafana-dashboards.yml config/grafana/provisioning/dashboards/dashboards.yml
fi

if [ -f "streaming-dashboard.json" ]; then
    mv streaming-dashboard.json config/grafana/dashboards/streaming.json
fi

# Scripts
if [ -f "scripts-start_stream.sh" ]; then
    mv scripts-start_stream.sh scripts/start_stream.sh
    chmod +x scripts/start_stream.sh
fi

if [ -f "scripts-stop_stream.sh" ]; then
    mv scripts-stop_stream.sh scripts/stop_stream.sh
    chmod +x scripts/stop_stream.sh
fi

# Node-RED flows
if [ -f "nodered-flows.json" ]; then
    mv nodered-flows.json config/nodered/flows.json
fi

# Set proper permissions
echo "Setting permissions..."
chmod +x scripts/*.sh
chmod 755 logs media

# Create sample media placeholder
echo "Creating sample media files..."
cat > media/README.md << 'EOF'
# Media Files Directory

Place your video files here for streaming tests.

## Supported Formats
- MP4 (recommended)
- MKV
- AVI
- MOV

## Example Usage
```bash
# Stream a video file
./scripts/start_stream.sh 0 live/stream sample.mp4

# 5-minute test with custom settings  
BITRATE=2000k RESOLUTION=1920x1080 ./scripts/start_stream.sh 300 live/hd movie.mp4
```

## Sample Files
You can download test videos from:
- https://sample-videos.com/
- https://test-videos.co.uk/
- Create your own with: `ffmpeg -f lavfi -i testsrc=duration=30:size=1280x720:rate=30 -f lavfi -i sine=frequency=1000:duration=30 -c:v libx264 -c:a aac sample.mp4`
EOF

# Verify Docker and Docker Compose
echo "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    echo "   https://docs.docker.com/get-docker/"
    exit 1
else
    echo "✅ Docker found: $(docker --version)"
fi

if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found or too old. Please install Docker Compose v2.0+."
    exit 1
else
    echo "✅ Docker Compose found: $(docker compose version)"
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  FFmpeg not found. Install FFmpeg to use streaming scripts:"
    echo "   Ubuntu/Debian: sudo apt install ffmpeg"
    echo "   macOS: brew install ffmpeg"
    echo "   Windows: Download from https://ffmpeg.org/"
else
    echo "✅ FFmpeg found: $(ffmpeg -version | head -n1)"
fi

echo
echo "=== Setup Complete! ==="
echo
echo "📁 Directory structure created"
echo "🔧 Configuration files organized"  
echo "🔐 Permissions set correctly"
echo
echo "🚀 Next Steps:"
echo "1. docker compose up -d"
echo "2. Access Grafana: http://localhost:3000 (admin/admin)"
echo "3. Access Node-RED: http://localhost:1880"  
echo "4. Test streaming: ./scripts/start_stream.sh 300 live/test testsrc"
echo
echo "📖 Read README.md for detailed instructions"
echo "💡 Check media/README.md for sample video files"

# Check for port conflicts
echo
echo "🔍 Checking for port conflicts..."
PORTS=(1935 3000 9090 1880 9093 9998)
CONFLICTS=()

for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        CONFLICTS+=($port)
    fi
done

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo "⚠️  Port conflicts detected: ${CONFLICTS[*]}"
    echo "   Stop services using these ports or modify docker-compose.yml"
else
    echo "✅ All required ports are available"
fi