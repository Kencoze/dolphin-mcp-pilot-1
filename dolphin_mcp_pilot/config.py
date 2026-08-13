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

"""Configuration management"""

import os

# ---- DolphinScheduler API ----
DS_API_BASE = os.environ.get("DS_URL", "").strip()
DS_USER = os.environ.get("DS_USER", "")
DS_PASSWORD = os.environ.get("DS_PASSWORD", "")
# Optional: API token auth (DolphinScheduler 3.x native token)
# If provided, will be preferred over user/password login
DS_TOKEN = os.environ.get("DS_TOKEN", "")

# ---- Tenant code used when creating workflows ----
# Default "default" works on most DS deployments.
# Override via env DS_TENANT_CODE if your org uses a custom tenant.
DS_TENANT_CODE = os.environ.get("DS_TENANT_CODE", "default")

# ---- MCP server ----
DS_MCP_TRANSPORT = os.environ.get("DS_MCP_TRANSPORT", "stdio").strip().lower()
MCP_PORT = int(os.environ.get("MCP_PORT", "8001"))
MCP_HOST = os.environ.get("MCP_HOST", "0.0.0.0")  # nosec B104 -- required for containerized HTTP server


def get_ds_url() -> str:
    """Return the DolphinScheduler API base URL (no trailing slash)."""
    if not DS_API_BASE:
        raise ValueError(
            "DS_URL is not configured. "
            "Set env DS_URL to your DolphinScheduler API base, "
            "e.g. http://your-ds-host:12345/dolphinscheduler"
        )
    return DS_API_BASE.rstrip("/")


def get_tenant_code() -> str:
    """Return the tenant code used for workflow creation."""
    return DS_TENANT_CODE


def get_ds_credentials() -> tuple[str, str]:
    """Return default credentials from environment.

    In HTTP mode, per-request credentials from headers
    (X-DS-User / X-DS-Password or X-DS-Token) take precedence,
    handled by the auth module via contextvars.
    """
    user = DS_USER.strip()
    pwd = DS_PASSWORD.strip()
    if not user or not pwd:
        raise ValueError(
            "No DolphinScheduler credentials found.\n"
            "  stdio mode: set env DS_USER / DS_PASSWORD, or DS_TOKEN\n"
            "  http  mode: set HTTP headers X-DS-User / X-DS-Password, or X-DS-Token"
        )
    return user, pwd


def get_ds_token_env() -> str:
    """Return API token from environment (may be empty)."""
    return DS_TOKEN.strip()
