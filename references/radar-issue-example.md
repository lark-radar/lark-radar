# 🛰️ 飞书生态开源项目雷达 · 2026-05-12

观察窗口：2026-05-05 ~ 2026-05-12  
覆盖：13 个活跃观察项目 + 3 个休眠观察项目

---

## 1. 本期速览

飞书开源生态本周活跃点主要集中在 **CLI 工具、MCP 接入、AI Agent 协作** 三个方向。

本周有明确代码更新的项目包括：

- [riba2534/feishu-cli](https://github.com/riba2534/feishu-cli)：10 个 commits，4 个近期 PR，最活跃
- [danielwpz/pokoclaw](https://github.com/danielwpz/pokoclaw)：10 个 commits，5 个近期 PR，继续推进 MCP / Agent 工作流
- [cso1z/Feishu-MCP](https://github.com/cso1z/Feishu-MCP)：新增 Bearer Token 认证能力
- [danielwpz/lark-a2ui-renderer](https://github.com/danielwpz/lark-a2ui-renderer)：A2UI 飞书卡片渲染相关更新

整体来看，**飞书文档工具链趋于稳定，AI Agent / MCP 方向仍在快速演进**。

---

## 2. 各项目进展

### 🔥 [riba2534/feishu-cli](https://github.com/riba2534/feishu-cli)

本周最活跃项目，主要更新包括：

- 新增 `board` 相关能力：SVG 导入、Mermaid 本地引擎、飞书原生节点转换
- 消息能力增强：自动展开合并转发消息
- Drive / Wiki / Task 等命令能力扩展
- 社区 PR 活跃，包括 video 导入导出、auth refresh、board clone 修复

这是目前飞书生态里维护质量最高的第三方 CLI 工具之一。

### 🔥 [danielwpz/pokoclaw](https://github.com/danielwpz/pokoclaw)

本周持续高频更新，重点包括：

- 新增 MCP client support
- 修复 bash full-access prefix / approval reuse 相关问题
- 增加 Linux compatibility CI
- 推进飞书里的长期 AI Agent 协作体验

它代表的是“飞书不只是 Bot 入口，而是 AI Agent 工作流承载界面”的方向。

### 🔥 [cso1z/Feishu-MCP](https://github.com/cso1z/Feishu-MCP)

本周主要更新：

- [PR #94](https://github.com/cso1z/Feishu-MCP/pull/94)：支持 Bearer Token 认证配置，已合并
- [PR #93](https://github.com/cso1z/Feishu-MCP/pull/93)：user 认证模式下缓存 token 安全修复，仍 open

MCP 是飞书生态接入 AI 编码工具的重要方向，这个项目值得持续跟踪。

---

## 3. 社区热点分析

### 热点 1：MCP 正在成为飞书生态新入口

相关项目：

- [cso1z/Feishu-MCP](https://github.com/cso1z/Feishu-MCP)
- [danielwpz/pokoclaw](https://github.com/danielwpz/pokoclaw)
- [op7418/Claude-to-IM-skill](https://github.com/op7418/Claude-to-IM-skill)

本周 MCP 相关项目都在推进认证、安全、Agent 接入能力。这个方向值得作为雷达重点长期跟踪。

### 热点 2：飞书文档工具链进入“深水区”

相关项目：

- [riba2534/feishu-cli](https://github.com/riba2534/feishu-cli)
- [whale4113/cloud-document-converter](https://github.com/whale4113/cloud-document-converter)
- [dicarne/feishu-backup](https://github.com/dicarne/feishu-backup)
- [eternalfree/feishu-doc-export](https://github.com/eternalfree/feishu-doc-export)

基础导出能力已经有人做了，现在问题集中在复杂 block、表格、视频、画板、嵌入内容等细节上。

### 热点 3：高 Star 项目存在维护压力

需要关注：

- [m1heng/clawdbot-feishu](https://github.com/m1heng/clawdbot-feishu)：4,284 stars，117 open items
- [op7418/Claude-to-IM-skill](https://github.com/op7418/Claude-to-IM-skill)：2,485 stars，93 open items

这两个项目说明需求真实存在，但维护压力较大。后续可以观察是否有官方支持、社区接力或替代项目出现。

---

## 4. 雷达总表

| 项目 | Stars | 本周动态 | 方向 |
|---|---:|---|---|
| [m1heng/clawdbot-feishu](https://github.com/m1heng/clawdbot-feishu) | 4,284 | 💤 无新增 commit | AI Agent 接入 |
| [op7418/Claude-to-IM-skill](https://github.com/op7418/Claude-to-IM-skill) | 2,485 | 📋 2 个近期 PR | IM Bridge |
| [riba2534/feishu-cli](https://github.com/riba2534/feishu-cli) | 947 | 🔥 10 commits / 4 PRs | CLI 工具 |
| [cso1z/Feishu-MCP](https://github.com/cso1z/Feishu-MCP) | 636 | 🔥 1 commit / 2 PRs | MCP |

---

## 5. 休眠观察

| 项目 | Stars | 最后更新 | 说明 |
|---|---:|---|---|
| [ConnectAI-E/feishu-openai](https://github.com/ConnectAI-E/feishu-openai) | 5,646 | 2025-07 | 高 Star，但已 10 个月无代码更新 |
| [Wsine/feishu2md](https://github.com/Wsine/feishu2md) | 2,147 | 2025-12 | 作者明确寻找维护者 |
| [ConnectAI-E/Feishu-Midjourney](https://github.com/ConnectAI-E/Feishu-Midjourney) | 436 | 2025-02 | 长期无更新 |

---

Made by [Pokoclaw](https://github.com/danielwpz/pokoclaw) with love 💜
