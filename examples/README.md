# Configuration Examples

This directory contains example configurations for various MCP clients.

## 📁 Files

### `codebuddy-config.json`
Configuration for **CodeBuddy** IDE with HTTP mode and token authentication.

**Usage:**
1. Copy the content to your CodeBuddy MCP settings
2. Replace `your_api_token_here` with your actual DolphinScheduler API token
3. Adjust the URL if your service is not on localhost

### `claude-desktop-config.json`
Configuration for **Claude Desktop** using stdio mode with Docker.

**Usage:**
1. Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac)
   or `%APPDATA%\Claude\claude_desktop_config.json` (Windows)
2. Update `/path/to/your/.env` to your actual `.env` file path
3. Restart Claude Desktop

### `http-auth-token.json`
HTTP mode with API token authentication (recommended).

**Best for:**
- Production deployments
- Multi-tenant scenarios
- Long-running services

### `http-auth-password.json`
HTTP mode with username/password authentication (fallback).

**Best for:**
- Development/testing
- When API tokens are not available
- Legacy DolphinScheduler versions

## 🔐 Authentication Methods

### Method 1: API Token (Recommended)

**Pros:**
- More secure (can be revoked without changing password)
- Better for automation
- Native DolphinScheduler 3.x feature

**How to get token:**
1. Log in to DolphinScheduler Web UI
2. Go to **User Center** → **Token Management**
3. Click **Create Token**
4. Set expiration and generate
5. Copy the token

**Config:**
```json
{
  "headers": {
    "X-DS-Token": "your_token_here"
  }
}
```

### Method 2: Username/Password

**Pros:**
- Works with all DolphinScheduler versions
- No token management needed

**Cons:**
- Less secure
- Session-based (cached internally)

**Config:**
```json
{
  "headers": {
    "X-DS-User": "your_username",
    "X-DS-Password": "your_password"
  }
}
```

## 🌐 Transport Modes

### HTTP Mode (Recommended for remote access)

**Pros:**
- Multi-tenant support (per-request auth)
- Can be accessed remotely
- Better for production

**Setup:**
```bash
DS_MCP_TRANSPORT=http docker-compose up -d
```

**Client config:**
```json
{
  "type": "sse",
  "url": "http://your-server:8001/mcp/"
}
```

### stdio Mode (For local tools)

**Pros:**
- Direct process communication
- Lower latency
- Simpler for single-user scenarios

**Setup:**
```bash
python -m dolphin_mcp_pilot
```

**Client config:**
```json
{
  "command": "python",
  "args": ["-m", "dolphin_mcp_pilot"]
}
```

## 🔧 Customization

### Change port

In `.env`:
```bash
MCP_PORT=9000
```

Update client config:
```json
{
  "url": "http://localhost:9000/mcp/"
}
```

### Remote deployment

In `.env`:
```bash
MCP_HOST=0.0.0.0  # Allow external access
```

Update client config:
```json
{
  "url": "http://your-server-ip:8001/mcp/"
}
```

### HTTPS (with reverse proxy)

Use nginx/Caddy/Traefik in front:

```json
{
  "url": "https://mcp.yourdomain.com/mcp/"
}
```

See [DEPLOYMENT.md](../DEPLOYMENT.md#enable-https) for details.

## 📚 More Information

- [Main README](../README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [DolphinScheduler Documentation](https://dolphinscheduler.apache.org/)
