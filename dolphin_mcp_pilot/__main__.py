#!/usr/bin/env python3
# Copyright 2026 iFLYTEK CO., LTD.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Main entry point.

Run modes:
    stdio: python -m dolphin_mcp_pilot
    http:  DS_MCP_TRANSPORT=http python -m dolphin_mcp_pilot

Env vars:
    DS_URL             DolphinScheduler API base URL (required)
    DS_USER            Default username (stdio mode; fallback in http mode)
    DS_PASSWORD        Default password
    DS_TOKEN           API token (preferred over user/password)
    DS_TENANT_CODE     Tenant code used when creating workflows (default: "default")
    DS_MCP_TRANSPORT   "stdio" (default) or "http"
    MCP_HOST           HTTP host to bind (default: 0.0.0.0)
    MCP_PORT           HTTP port to bind (default: 8001)

HTTP mode per-request auth headers:
    X-DS-Token:     API token (preferred)
    X-DS-User:      username
    X-DS-Password:  password
"""

import sys
from contextlib import asynccontextmanager

import anyio
import uvicorn
from starlette.applications import Starlette
from starlette.routing import Mount

from .config import DS_MCP_TRANSPORT, MCP_HOST, MCP_PORT
from .middleware import AuthMiddleware
from .server import mcp


@asynccontextmanager
async def lifespan(app: Starlette):
    """Run the MCP session manager for the lifetime of the app."""
    async with mcp.session_manager.run():
        yield


def main() -> None:
    if DS_MCP_TRANSPORT == "http":
        # Use stateless HTTP transport (MCP 2.0)
        # Create streamable HTTP app with explicit host configuration
        # MCP_HOST defaults to 0.0.0.0 in Docker, but streamable_http_app() defaults to 127.0.0.1
        # We must pass the host parameter to avoid DNS-rebinding protection blocking non-localhost requests
        mcp_app = mcp.streamable_http_app(
            stateless_http=True,
            streamable_http_path="/mcp/",
            host=MCP_HOST,  # Use the configured host (0.0.0.0 for Docker, or specific host)
        )

        # Mount the MCP app at root, it will handle /mcp/ internally
        starlette_app = Starlette(
            debug=False,
            routes=[Mount("/", app=mcp_app)],
            lifespan=lifespan,
        )
        starlette_app.add_middleware(AuthMiddleware)

        config = uvicorn.Config(
            starlette_app,
            host=MCP_HOST,
            port=MCP_PORT,
            log_level="info",
        )
        print(f"dolphin-mcp-pilot listening on http://{MCP_HOST}:{MCP_PORT}/mcp/")
        print("Pass X-DS-Token or X-DS-User/X-DS-Password headers per request.")
        anyio.run(uvicorn.Server(config).serve)
    else:
        print("dolphin-mcp-pilot starting in stdio mode", file=sys.stderr)
        mcp.run()


if __name__ == "__main__":
    main()
