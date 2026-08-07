#!/bin/bash
# Quick start script for dolphin-mcp-pilot (Linux/Mac)

set -e

echo "🐬 Starting dolphin-mcp-pilot..."
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo ""
    echo "Please follow these steps:"
    echo "  1. Copy the example config: cp .env.example .env"
    echo "  2. Edit .env and configure your DolphinScheduler connection"
    echo "  3. Run this script again"
    echo ""
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

# Start the service
echo "📦 Building and starting containers..."
docker-compose up -d

# Wait a moment for the service to start
sleep 2

# Check if container is running
if docker ps | grep -q dolphin-mcp-pilot; then
    echo ""
    echo "✅ dolphin-mcp-pilot is running!"
    echo ""
    echo "📍 Service URL: http://localhost:8001/mcp/"
    echo ""
    echo "📖 Next steps:"
    echo "  - Check status: docker ps | grep dolphin-mcp-pilot"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Stop service: docker-compose down"
    echo ""
else
    echo ""
    echo "⚠️  Container may not have started successfully"
    echo "Check logs with: docker-compose logs"
    exit 1
fi
