# ---------- Stage 1: build dependencies into a self-contained venv ----------
FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=300

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --timeout 300 -r requirements.txt

# ---------- Stage 2: slim runtime image ----------
FROM python:3.12-slim

LABEL maintainer="dolphin-mcp-pilot contributors" \
      description="dolphin-mcp-pilot - DolphinScheduler MCP Server (open source)" \
      org.opencontainers.image.title="dolphin-mcp-pilot" \
      org.opencontainers.image.description="Production-ready MCP server for Apache DolphinScheduler" \
      org.opencontainers.image.licenses="Apache-2.0"

# Create a non-root user (fixed UID/GID 1001 for stable volume permissions)
RUN groupadd --gid 1001 dolphin && \
    useradd --uid 1001 --gid dolphin --create-home --shell /bin/sh dolphin_mcp

# Bring in the venv from the builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    VIRTUAL_ENV="/opt/venv"

WORKDIR /app

# Copy application source owned by the non-root user
COPY --chown=1001:1001 dolphin_mcp_pilot ./dolphin_mcp_pilot

EXPOSE 8001

ENV DS_MCP_TRANSPORT=http \
    MCP_HOST=0.0.0.0 \
    MCP_PORT=8001 \
    PYTHONUNBUFFERED=1

# Health check: verify the MCP HTTP endpoint is responding correctly.
# Sends a JSON-RPC tools/list request to ensure the server is functional.
# Uses only stdlib (no curl/wget install cost).
# Must include Accept header for MCP 2.0 stateless protocol.
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import urllib.request, json; req = urllib.request.Request('http://127.0.0.1:8001/mcp/', data=json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list', 'params': {}}).encode(), headers={'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'}, method='POST'); resp = urllib.request.urlopen(req, timeout=5); exit(0 if resp.status == 200 else 1)"]

USER 1001:1001

CMD ["python", "-m", "dolphin_mcp_pilot"]
