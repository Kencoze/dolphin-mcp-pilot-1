# 🚀 Deployment Guide

Quick deployment guide for **dolphin-mcp-pilot**.

## 📋 Prerequisites

- **Docker** 20.10+ and **Docker Compose** 1.29+
- Access to a running **DolphinScheduler** instance (3.x recommended)
- DolphinScheduler API token or username/password

## ⚡ Quick Start (3 steps)

### 1. Clone the repository

```bash
git clone https://github.com/your-org/dolphin-mcp-pilot.git
cd dolphin-mcp-pilot
```

### 2. Configure environment

```bash
# Copy the example config
cp .env.example .env

# Edit .env with your favorite editor
nano .env  # or vim, code, notepad, etc.
```

**Required configuration:**
- `DS_URL`: Your DolphinScheduler API URL
- `DS_TOKEN`: Your API token (recommended)
  - OR `DS_USER` + `DS_PASSWORD` (fallback)

### 3. Start the service

**Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

**Windows:**
```cmd
start.bat
```

**Or manually:**
```bash
docker-compose up -d
```

✅ Service will be available at `http://localhost:8001/mcp/` (note the trailing slash)

## 🔍 Verify Deployment

### Test MCP handshake

```bash
curl -X POST http://localhost:8001/mcp/ \
  -H "X-DS-Token: your_token" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}'
```

Expected: an SSE `data:` line containing `"serverInfo":{"name":"DolphinScheduler",...}`

> **Note**: URL must end with `/`. Without it, Starlette returns HTTP 307 redirect,
> which some MCP clients fail to follow.

### View logs

```bash
docker-compose logs -f
```

### Check container status

```bash
docker ps | grep dolphin-mcp-pilot
```

## 🔧 Configuration Details

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DS_URL` | ✅ Yes | - | DolphinScheduler API base URL |
| `DS_TOKEN` | ⚠️ Recommended | - | API token (DolphinScheduler 3.x+) |
| `DS_USER` | ⚠️ If no token | - | Username (fallback auth) |
| `DS_PASSWORD` | ⚠️ If no token | - | Password (fallback auth) |
| `DS_TENANT_CODE` | ❌ No | `default` | Tenant code for workflow creation |
| `DS_MCP_TRANSPORT` | ❌ No | `http` | Transport mode: `stdio` or `http` |
| `MCP_HOST` | ❌ No | `0.0.0.0` | HTTP server bind address |
| `MCP_PORT` | ❌ No | `8001` | HTTP server port |

### Getting DolphinScheduler API Token

1. Log in to DolphinScheduler Web UI
2. Navigate to **User Center** → **Token Management**
3. Click **Create Token**
4. Set expiration date and generate
5. Copy the token to your `.env` file

## 🔌 Client Configuration

### CodeBuddy / Claude Desktop (HTTP mode)

Add to your MCP client config:

```json
{
  "mcpServers": {
    "dolphinscheduler": {
      "type": "sse",
      "url": "http://localhost:8001/mcp/",
      "headers": {
        "X-DS-Token": "your_api_token_here"
      }
    }
  }
}
```

See `examples/` directory for more configuration samples.

## 🐛 Troubleshooting

### Container won't start

**Check logs:**
```bash
docker-compose logs
```

**Common issues:**
- Missing `.env` file → Copy from `.env.example`
- Invalid `DS_URL` → Verify DolphinScheduler is accessible
- Port 8001 already in use → Change `MCP_PORT` in `.env`

### Connection refused

**Verify DolphinScheduler is reachable:**
```bash
curl http://your-ds-host:12345/dolphinscheduler/ui
```

**Check network:**
- If DolphinScheduler is on `localhost`, use `host.docker.internal` in Docker
- Ensure firewall allows connections

### Authentication failed

**Token mode:**
- Verify token is valid and not expired
- Check token has correct permissions

**Username/password mode:**
- Verify credentials are correct
- Check user account is not locked

### Tools not working

**Check DolphinScheduler version:**
- This MCP server is tested with DolphinScheduler 3.x
- Some APIs may differ in 2.x versions

**Verify permissions:**
- User/token must have appropriate project permissions
- Some operations require admin privileges

## 🔄 Updates

### Pull latest changes

```bash
git pull origin main
docker-compose down
docker-compose up -d --build
```

### View changelog

```bash
git log --oneline
```

## 🛑 Stop Service

```bash
docker-compose down
```

To remove volumes as well:
```bash
docker-compose down -v
```

## 📦 Production Deployment

### Use Docker image from registry

```yaml
# docker-compose.yml
services:
  dolphin-mcp-pilot:
    image: your-registry/dolphin-mcp-pilot:latest
    # ... rest of config
```

### Enable HTTPS

Use a reverse proxy (nginx, Caddy, Traefik) in front of the service:

```nginx
server {
    listen 443 ssl;
    server_name mcp.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /mcp {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### Resource limits

Add to `docker-compose.yml`:

```yaml
services:
  dolphin-mcp-pilot:
    # ... existing config
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Health checks

```yaml
services:
  dolphin-mcp-pilot:
    # ... existing config
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/mcp/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

## 📞 Support

- **Issues**: https://github.com/your-org/dolphin-mcp-pilot/issues
- **Discussions**: https://github.com/your-org/dolphin-mcp-pilot/discussions
- **DolphinScheduler Docs**: https://dolphinscheduler.apache.org/

## 📄 License

Apache-2.0
