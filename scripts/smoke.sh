#!/bin/bash
# dolphin-mcp-pilot smoke test
set -e

URL='http://localhost:8001/mcp/'
CT='Content-Type: application/json'
AC='Accept: application/json, text/event-stream'
# Replace with your DS credentials
U='X-DS-User: admin'
P='X-DS-Password: your-password'

curl -s -D /tmp/h.txt -H "$CT" -H "$AC" -H "$U" -H "$P" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"1"}}}' \
  "$URL" > /tmp/init.txt
SID=$(awk 'tolower($1)=="mcp-session-id:" {gsub("\r","",$2); print $2}' /tmp/h.txt)
curl -s -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' "$URL" > /dev/null

echo "=== Tool count ==="
TOTAL=$(curl -s -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  "$URL" | grep -o '"name":"ds_' | wc -l)
echo "TOTAL=$TOTAL (expected 58)"

echo
echo "=== Instructions field ==="
grep -q '"instructions"' /tmp/init.txt && echo "FOUND instructions" || echo "MISSING instructions"

echo
echo "=== ds_help test ==="
curl -s --max-time 15 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"ds_help","arguments":{}}}' \
  "$URL" > /tmp/resp.txt
if grep -q '"isError":true' /tmp/resp.txt; then
  echo "FAIL: ds_help returned error"
else
  echo "PASS: ds_help"
fi

echo
echo "=========================================="
if [ "$TOTAL" -eq 58 ]; then
  echo "✅ PASS (dolphin-mcp-pilot v0.2.0 with 58 tools)"
else
  echo "❌ FAIL (tool count=$TOTAL, expected=58)"
fi
echo "=========================================="
