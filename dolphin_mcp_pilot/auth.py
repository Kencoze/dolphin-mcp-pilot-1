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

"""Authentication & session management.

Supports two auth modes:
  1. API Token (DolphinScheduler 3.x native) - preferred, no session needed.
  2. User/Password login - obtains a sessionId, cached for 30 min.

Per-request credentials are stored in contextvars so HTTP concurrency
works correctly (each request/coroutine has its own user).
"""

from __future__ import annotations

import contextvars
import json
import time
import urllib.parse
import urllib.request

from .config import get_ds_url, get_ds_credentials, get_ds_token_env

# ---- per-request credentials ----
_current_ds_user: contextvars.ContextVar[str] = contextvars.ContextVar(
    "_current_ds_user"
)
_current_ds_password: contextvars.ContextVar[str] = contextvars.ContextVar(
    "_current_ds_password"
)
_current_ds_token: contextvars.ContextVar[str] = contextvars.ContextVar(
    "_current_ds_token"
)

# ---- session cache: user -> (sessionId, timestamp) ----
_session_cache: dict[str, tuple[str, float]] = {}
SESSION_TIMEOUT = 1800  # 30 minutes


def set_current_credentials(
    user: str = "",
    password: str = "",
    token: str = "",
) -> None:
    """Set per-request credentials (called by HTTP middleware)."""
    if user:
        _current_ds_user.set(user)
    if password:
        _current_ds_password.set(password)
    if token:
        _current_ds_token.set(token)


def get_current_token() -> str:
    """Return per-request token if set, else env DS_TOKEN."""
    try:
        t = _current_ds_token.get()
        if t:
            return t
    except LookupError:
        pass
    return get_ds_token_env()


def get_credentials() -> tuple[str, str]:
    """Return user/password, preferring per-request over env."""
    try:
        user = _current_ds_user.get()
        pwd = _current_ds_password.get()
        if user and pwd:
            return user, pwd
    except LookupError:
        pass
    return get_ds_credentials()


def login() -> str:
    """Login with user/password and return sessionId.

    Cached for 30 minutes per user.
    Do NOT call this when token auth is used; use get_current_token() instead.
    """
    user, pwd = get_credentials()
    cache_key = user

    # cache hit
    cached = _session_cache.get(cache_key)
    if cached:
        sid, ts = cached
        if time.time() - ts < SESSION_TIMEOUT:
            return sid

    # login
    url = get_ds_url()
    body = urllib.parse.urlencode({"userName": user, "userPassword": pwd}).encode()
    req = urllib.request.Request(
        f"{url}/login",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(req, timeout=30) as resp:
        result = json.loads(resp.read().decode())

    if result.get("code") != 0:
        raise RuntimeError(
            f"DolphinScheduler login failed: {result.get('msg', result)}"
        )

    sid = result["data"]["sessionId"]
    _session_cache[cache_key] = (sid, time.time())
    return sid


def clear_cache(user: str | None = None) -> None:
    """Clear session cache for a user, or all users."""
    if user:
        _session_cache.pop(user, None)
    else:
        _session_cache.clear()
