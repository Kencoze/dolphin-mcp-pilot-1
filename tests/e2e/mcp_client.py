"""Lightweight MCP-over-HTTP JSON-RPC client for e2e tests.

Uses only Python stdlib (urllib.request, json) so the e2e suite
has no extra runtime dependencies beyond pytest.

Supports MCP 2.0 (2026-07-28) stateless protocol:
- No initialize/initialized handshake
- No Mcp-Session-Id header
- Per-request authentication via X-DS-Token or X-DS-User/X-DS-Password
"""

import json
import urllib.request


class MCPClient:
    """Minimal MCP client for tests.

    Supports user/password or token auth and handles both JSON and SSE responses.
    Works with MCP 2.0 stateless protocol (no session management).
    """

    def __init__(self, base_url, user="", password="", token=""):
        self.base_url = base_url.rstrip("/") + "/mcp/"
        self.user = user
        self.password = password
        self.token = token
        self._req_id = 0

    def _next_id(self):
        self._req_id += 1
        return self._req_id

    def _headers(self):
        h = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        # Per-request authentication (stateless protocol)
        if self.user and self.password:
            h["X-DS-User"] = self.user
            h["X-DS-Password"] = self.password
        if self.token:
            h["X-DS-Token"] = self.token
        # Note: No Mcp-Session-Id header in MCP 2.0 stateless mode
        return h

    def _call(self, payload):
        req = urllib.request.Request(
            self.base_url,
            data=json.dumps(payload).encode("utf-8"),
            headers=self._headers(),
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            # MCP 2.0 stateless: no session ID in response
            body = resp.read().decode("utf-8")
            ct = resp.headers.get("Content-Type") or ""
            if "text/event-stream" in ct:
                return self._parse_sse(body)
            return json.loads(body) if body else {}

    @staticmethod
    def _parse_sse(body):
        for line in body.strip().split("\n"):
            if line.startswith("data: "):
                return json.loads(line[6:])
        raise ValueError(f"No SSE data found in: {body[:200]}")

    def initialize(self):
        """MCP 2.0: No handshake required. This method is a no-op for compatibility."""
        # In MCP 2.0 (2026-07-28), the initialize/initialized handshake is removed.
        # The protocol is stateless, so we can call tools directly.
        return {"protocolVersion": "2026-07-28", "capabilities": {}}

    def tools_list(self):
        """Return the list of registered tools."""
        resp = self._call(
            {
                "jsonrpc": "2.0",
                "id": self._next_id(),
                "method": "tools/list",
                "params": {},
            }
        )
        return resp.get("result", {}).get("tools", [])

    def call_tool(self, name, arguments=None):
        """Call an MCP tool and return the raw JSON-RPC response."""
        return self._call(
            {
                "jsonrpc": "2.0",
                "id": self._next_id(),
                "method": "tools/call",
                "params": {"name": name, "arguments": arguments or {}},
            }
        )
