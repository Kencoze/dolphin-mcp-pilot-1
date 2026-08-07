# Contributing to dolphin-mcp-pilot

感谢你对 dolphin-mcp-pilot 的关注！本文档说明如何参与项目贡献。

---

## 行为准则

本项目遵循讯飞开源社区行为准则，要求所有参与者：
- 尊重他人，保持专业、友善的交流态度
- 遵守公司信息安全与知识产权管理规范
- **禁止私自外传、拷贝、商用项目代码或离线备份**
- 所有贡献需经过代码评审，留痕审计

---

## 贡献流程

### 1. 前置准备

```bash
# Fork 项目并克隆到本地
git clone https://github.com/your-username/dolphin-mcp-pilot.git
cd dolphin-mcp-pilot

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 填写 DS_URL / DS_USER / DS_PASSWORD
```

### 2. 开发规范

#### 分支策略

本项目采用四级分支体系：

- **main**：稳定主干分支，只接受经评审的 PR，禁止直接提交
- **dev**：开发集成分支，日常迭代在此分支进行
- **feature/xxx**：功能分支，从 dev 切出，完成后合入 dev
- **bugfix/xxx 或 hotfix/xxx**：修复分支，紧急修复可直接合入 main

#### 代码规范

- Python 代码遵循 PEP 8 规范，使用 `black` 格式化
- 所有函数/类必须有 docstring 说明
- 变量命名语义化，使用 snake_case 风格
- 提交前运行 `black .` 和 `pylint dolphin_mcp_pilot/`

#### 提交规范

遵循 Conventional Commits 格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**type 类型**：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链配置

**示例**：
```
feat(tools): 新增 ds_get_cluster_status 监控工具

- 支持查询 master/worker 节点健康状态
- 返回 CPU/内存/任务队列长度
- 更新 ds_help 工具分类

Closes #42
```

### 3. 提交 Pull Request

```bash
# 创建功能分支
git checkout -b feature/my-new-feature dev

# 开发完成后提交
git add .
git commit -m "feat(scope): description"
git push origin feature/my-new-feature
```

在 GitHub 提交 PR，填写以下信息：

**PR 标题**：遵循提交规范格式  
**PR 描述**：
- 修改内容说明
- 关联 Issue（如有）
- 自测结果（是否通过 smoke test）
- 截图/日志（如适用）

**评审要求**：
- 至少 1 名 OWNERS 中的 reviewer 审批通过
- CI 流水线全部通过（代码格式、安全扫描、单元测试）
- 无冲突，可自动合并

### 4. 代码评审

Reviewer 将检查：
- 代码质量与规范性
- 是否引入安全风险（敏感信息、SQL 注入、路径遍历等）
- 是否破坏现有功能
- 测试覆盖是否充分
- 文档是否同步更新

修改意见需在 2 个工作日内响应并修复。

---

## 开发指南

### 添加新工具

1. 在 `dolphin_mcp_pilot/tools/` 对应模块文件中添加函数
2. 使用 `@mcp.tool()` 装饰器注册
3. 编写完整 docstring（包含参数说明、返回值、使用示例）
4. 在 `tools/help.py` 中更新工具分类和说明
5. 添加单元测试到 `tests/`
6. 更新 `CHANGELOG.md`

**示例**：

```python
# dolphin_mcp_pilot/tools/monitor.py

@mcp.tool()
def ds_get_cluster_status() -> dict:
    """获取 DolphinScheduler 集群健康状态。
    
    返回 master/worker 节点的 CPU、内存、任务队列等监控指标。
    
    Returns:
        dict: {
            "masters": [{"host": "10.1.1.1", "cpu": 45.2, ...}],
            "workers": [{"host": "10.1.1.2", "cpu": 78.1, ...}]
        }
    """
    # 实现逻辑
    ...
```

### 运行测试

```bash
# 单元测试
pytest tests/

# 冒烟测试（需配置 .env）
bash scripts/smoke.sh

# 代码格式检查
black --check .
pylint dolphin_mcp_pilot/
```

### 本地调试

```bash
# stdio 模式（用于 Claude Desktop / CodeBuddy）
python -m dolphin_mcp_pilot

# HTTP 模式（用于 Web 客户端）
DS_MCP_TRANSPORT=http MCP_PORT=8001 python -m dolphin_mcp_pilot
```

---

## 版本发布

由项目负责人（OWNERS 中的 approvers）执行：

1. 更新 `pyproject.toml` 中的 `version`
2. 更新 `CHANGELOG.md`，汇总本版本所有变更
3. 创建 git tag：`git tag v0.x.0`
4. 推送 tag：`git push origin v0.x.0`
5. 在 GitHub Releases 发布版本，附带 Release Notes

**版本规则**：遵循语义化版本（Semantic Versioning）
- **主版本号**：不兼容的 API 变更
- **次版本号**：向下兼容的功能新增
- **补丁版本号**：向下兼容的问题修复

**迭代节奏**：
- 月度补丁版本（bugfix + 小优化）
- 季度次版本（新功能）

---

## 报告问题

发现 bug 或有功能建议，请在 GitHub Issues 提交：

**Bug 报告**需包含：
- 问题描述
- 复现步骤
- 预期行为 vs 实际行为
- 环境信息（Python 版本、DolphinScheduler 版本、操作系统）
- 相关日志/截图

**功能建议**需包含：
- 使用场景
- 预期实现方式
- 替代方案（如有）

---

## 知识产权声明

**重要**：本项目知识产权归科大讯飞股份有限公司独家所有。

- 所有贡献代码的版权归公司所有
- 贡献者保留署名权
- **禁止私自外传、拷贝、商用本项目代码或离线备份**
- 如需对外开源或商业使用，必须经过公司开源管理办公室（OSPO）三级审批

---

## 联系方式

- **Issue 讨论**：https://github.com/iflytek/dolphin-mcp-pilot/issues
- **OSPO 归口**：开源管理办公室
- **项目负责人**：廖珺辉 (@Hui-of-limin)
- **Co-maintainer**：@charleswillicks

---

感谢你的贡献！🎉
