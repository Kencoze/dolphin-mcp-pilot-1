# MCP 1.0 到 2.0 迁移指南

本文档介绍如何将 dolphin-mcp-pilot 从 MCP 1.x 升级到 MCP 2.0，以及客户端需要做的相应调整。

## 概览

dolphin-mcp-pilot 已升级到 MCP Python SDK v2.0.0，支持 2026-07-28 版本的无状态协议。主要变化包括：

- ✅ **无状态协议**：移除了会话管理，每个请求独立
- ✅ **简化握手**：移除了 `initialize`/`initialized` 握手过程
- ✅ **移除会话头**：不再需要 `Mcp-Session-Id` 头
- ✅ **每请求认证**：通过 HTTP 头在每个请求中传递凭证
- ✅ **负载均衡友好**：任何请求可以路由到任何服务器实例

## 协议变化

### MCP 1.x（旧版）

```
客户端                          服务器
  |                               |
  |--- initialize (握手) -------->|
  |<-- initialize result ---------|
  |--- notifications/initialized ->|
  |                               |
  |--- tools/call (带 session-id) ->|
  |<-- result (带 session-id) ----|
```

**特点：**
- 需要初始化握手
- 每个连接维护会话状态
- 使用 `Mcp-Session-Id` 头跟踪会话
- 有状态的连接

### MCP 2.0（新版）

```
客户端                          服务器
  |                               |
  |--- tools/call (带认证头) ----->|
  |<-- result ---------------------|
```

**特点：**
- 无需握手，直接调用工具
- 无状态，每个请求独立
- 不使用会话 ID
- 每请求携带认证信息

## 客户端迁移步骤

### 1. 移除初始化握手

**MCP 1.x 代码：**

```python
import requests

# 1. 初始化握手
response = requests.post(
    "http://localhost:8001/mcp/",
    headers={"Content-Type": "application/json"},
    json={
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "my-client", "version": "1.0"}
        }
    }
)
session_id = response.headers.get("Mcp-Session-Id")

# 2. 发送 initialized 通知
requests.post(
    "http://localhost:8001/mcp/",
    headers={
        "Content-Type": "application/json",
        "Mcp-Session-Id": session_id
    },
    json={
        "jsonrpc": "2.0",
        "method": "notifications/initialized",
        "params": {}
    }
)

# 3. 调用工具
response = requests.post(
    "http://localhost:8001/mcp/",
    headers={
        "Content-Type": "application/json",
        "Mcp-Session-Id": session_id,
        "X-DS-User": "admin",
        "X-DS-Password": "password"
    },
    json={
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {"name": "ds_list_projects", "arguments": {}}
    }
)
```

**MCP 2.0 代码：**

```python
import requests

# 直接调用工具，无需握手
response = requests.post(
    "http://localhost:8001/mcp/",
    headers={
        "Content-Type": "application/json",
        "X-DS-User": "admin",
        "X-DS-Password": "password"
    },
    json={
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": "ds_list_projects", "arguments": {}}
    }
)
```

### 2. 移除会话 ID 管理

**MCP 1.x：**

```python
class MCPClient:
    def __init__(self):
        self.session_id = None
    
    def initialize(self):
        # 获取 session_id
        response = requests.post(...)
        self.session_id = response.headers.get("Mcp-Session-Id")
    
    def call_tool(self, name, args):
        # 使用 session_id
        headers = {"Mcp-Session-Id": self.session_id}
        response = requests.post(..., headers=headers)
```

**MCP 2.0：**

```python
class MCPClient:
    def __init__(self):
        # 无需 session_id
        pass
    
    def call_tool(self, name, args):
        # 每请求携带认证信息
        headers = {
            "X-DS-User": "admin",
            "X-DS-Password": "password"
        }
        response = requests.post(..., headers=headers)
```

### 3. 更新协议版本

如果你需要检查协议版本：

**MCP 1.x：**
```python
protocol_version = "2024-11-05"
```

**MCP 2.0：**
```python
protocol_version = "2026-07-28"
```

## Python SDK 迁移

### 使用官方 SDK

如果你使用 MCP Python SDK，升级非常简单：

**安装 MCP 2.0：**

```bash
pip install "mcp>=2.0.0,<3.0.0"
```

**使用 MCPServer（新名称）：**

```python
# MCP 1.x
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("MyServer")

# MCP 2.0
from mcp.server.mcpserver import MCPServer
mcp = MCPServer("MyServer")
```

**无状态 HTTP 服务器：**

```python
from mcp.server.mcpserver import MCPServer

mcp = MCPServer("MyServer")

# 注册工具
@mcp.tool()
def my_tool(arg: str) -> str:
    return f"Result: {arg}"

# 运行无状态 HTTP 服务器（MCP 2.0）
mcp.run(
    transport="streamable-http",
    host="0.0.0.0",
    port=8001,
    stateless_http=True,
)
```

**注意：** 
- 使用 `mcp.run()` 是最简单的方式，SDK 会自动处理所有配置
- `stateless_http=True` 启用无状态模式
- 默认端点路径是 `/mcp/`，客户端需要访问 `http://your-server:8001/mcp/`
- 如果需要自定义端点路径或添加中间件，才需要使用 `streamable_http_app()` 手动配置

## 认证方式

dolphin-mcp-pilot 支持两种认证方式，在 MCP 2.0 中保持不变：

### 1. 用户名/密码认证

```http
POST /mcp/ HTTP/1.1
Content-Type: application/json
X-DS-User: admin
X-DS-Password: your_password

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {"name": "ds_list_projects", "arguments": {}}
}
```

### 2. Token 认证

```http
POST /mcp/ HTTP/1.1
Content-Type: application/json
X-DS-Token: your_api_token

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {"name": "ds_list_projects", "arguments": {}}
}
```

## 多租户支持

MCP 2.0 的无状态特性使得多租户支持更加简单：

```python
# 用户 A 的请求
response_a = requests.post(
    "http://localhost:8001/mcp/",
    headers={
        "X-DS-User": "user_a",
        "X-DS-Password": "password_a"
    },
    json={...}
)

# 用户 B 的请求（完全独立）
response_b = requests.post(
    "http://localhost:8001/mcp/",
    headers={
        "X-DS-User": "user_b",
        "X-DS-Password": "password_b"
    },
    json={...}
)
```

每个请求携带自己的凭证，无需维护会话状态。

## 向后兼容性

### 服务器端

dolphin-mcp-pilot 同时支持 stdio 和 HTTP 传输：

- **stdio 模式**：`DS_MCP_TRANSPORT=stdio`（默认）
- **HTTP 模式**：`DS_MCP_TRANSPORT=http`

两种模式都使用 MCP 2.0 协议。

### 客户端

如果你的客户端还在使用 MCP 1.x：

1. **短期**：可以继续使用旧客户端连接 dolphin-mcp-pilot 1.x 版本
2. **长期**：建议升级到 MCP 2.0 客户端以使用新特性

## 部署注意事项

### Host 配置（重要！）

MCP 2.0 SDK 的 `streamable_http_app()` 默认启用 **DNS-rebinding 保护**，这是一个安全特性，但会影响部署：

**默认行为：**
```python
# 如果不指定 host 参数，默认值为 127.0.0.1
mcp.streamable_http_app(stateless_http=True)
# 结果：只接受 Host: localhost 或 Host: 127.0.0.1 的请求
# 其他域名或 IP 的请求会被拒绝，返回 421 Invalid Host header
```

**生产部署必须显式配置 host：**

```python
# Docker/Kubernetes 部署
mcp.streamable_http_app(
    stateless_http=True,
    host="0.0.0.0",  # 允许所有 Host 头
)

# 或者使用环境变量
import os
mcp.streamable_http_app(
    stateless_http=True,
    host=os.getenv("MCP_HOST", "0.0.0.0"),
)
```

**dolphin-mcp-pilot 的配置：**

dolphin-mcp-pilot 已经正确处理了这个配置：

```python
# dolphin_mcp_pilot/__main__.py
mcp_app = mcp.streamable_http_app(
    stateless_http=True,
    streamable_http_path="/mcp/",
    host=MCP_HOST,  # 从环境变量读取，默认 0.0.0.0
)
```

**验证部署：**

如果你在 Docker 或负载均衡器后面部署，可以通过以下方式验证：

```bash
# 使用域名访问（应该返回 200）
curl -H "Host: pilot.example.com" http://your-server:8001/mcp/

# 如果使用 localhost 访问（应该返回 200）
curl -H "Host: localhost:8001" http://localhost:8001/mcp/
```

如果返回 `421 Invalid Host header`，说明 Host 配置有问题。

### 负载均衡器配置

由于 MCP 2.0 是无状态协议，可以使用标准的负载均衡器（无需会话亲和性）：

**推荐配置：**
- ✅ 轮询（Round Robin）
- ✅ 最少连接（Least Connections）
- ✅ 基于 IP 哈希（如果有会话需求，但 MCP 2.0 不需要）

**不需要的配置：**
- ❌ 会话亲和性（Sticky Sessions）- MCP 2.0 无状态，不需要
- ❌ 特殊的路由规则 - 任何请求可以路由到任何实例

### 健康检查

Docker 镜像内置了健康检查（每 30 秒）：

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD nc -z 127.0.0.1 8001 || exit 1
```

这个健康检查在容器内部运行，使用 localhost，所以不受 Host 配置影响。

## 常见问题

### Q: 我需要修改现有代码吗？

**A:** 如果你使用 HTTP 客户端访问 dolphin-mcp-pilot，需要：
- 移除初始化握手代码
- 移除会话 ID 管理
- 确保每个请求都携带认证头

### Q: stdio 模式有变化吗？

**A:** stdio 模式的使用方式不变，但底层协议已升级到 MCP 2.0。大多数 MCP 客户端库会自动处理协议版本协商。

### Q: 性能有改进吗？

**A:** 是的！无状态协议带来了以下优势：
- 无需维护会话状态，减少内存占用
- 可以使用标准负载均衡器
- 更好的水平扩展能力
- 更简单的故障恢复

### Q: 部署后返回 421 Invalid Host header 怎么办？

**A:** 这是因为 MCP 2.0 SDK 默认启用了 DNS-rebinding 保护。确保：

1. **检查 MCP_HOST 环境变量**：Docker 部署时应设置为 `0.0.0.0`
   ```bash
   # .env 文件
   MCP_HOST=0.0.0.0
   ```

2. **验证配置**：查看容器日志，应该看到：
   ```
   dolphin-mcp-pilot listening on http://0.0.0.0:8001/mcp/
   ```

3. **测试访问**：
   ```bash
   # 使用实际域名测试
   curl -H "Host: your-domain.com" http://your-server:8001/mcp/
   ```

如果问题仍然存在，检查是否修改了代码中的 host 配置。dolphin-mcp-pilot 已经正确处理了这个配置，正常情况下不会出现此问题。

### Q: 如何验证迁移成功？

**A:** 运行 e2e 测试：

```bash
# 启动 DolphinScheduler 和 dolphin-mcp-pilot
docker compose up -d

# 运行 e2e 测试
pytest tests/e2e/ -v
```

## 参考资源

- [MCP 2.0 规范 (2026-07-28)](https://spec.modelcontextprotocol.io/specification/2026-07-28/)
- [MCP Python SDK 文档](https://github.com/modelcontextprotocol/python-sdk)
- [MCP Python SDK 迁移指南](https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/migration.md)
- [dolphin-mcp-pilot Issue #9](https://github.com/iflytek/dolphin-mcp-pilot/issues/9)

## 获取帮助

如果迁移过程中遇到问题：

1. 查看 [FAQ](FAQ.md)
2. 查看 [e2e 测试示例](e2e.md)
3. 提交 [GitHub Issue](https://github.com/iflytek/dolphin-mcp-pilot/issues)
