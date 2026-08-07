FROM python:3.12-slim

LABEL maintainer="dolphin-mcp-pilot contributors"
LABEL description="dolphin-mcp-pilot - DolphinScheduler MCP Server (open source)"

WORKDIR /app

# Use public pypi mirrors by default; override in build-time if needed.
# ENV PIP_INDEX_URL=https://pypi.org/simple/
ENV PIP_DEFAULT_TIMEOUT=300

COPY requirements.txt .
RUN pip install --no-cache-dir --timeout 300 -r requirements.txt

# Copy source (dolphin_mcp_pilot package is already at project root)
COPY . .

EXPOSE 8001

ENV DS_MCP_TRANSPORT=http
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8001

# Entrypoint (package already has __main__.py)
CMD ["python", "-m", "dolphin_mcp_pilot"]
