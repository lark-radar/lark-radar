---
name: lark-radar
version: 0.1.0
description: 维护飞书 / Lark 开源生态项目雷达，扫描 GitHub 项目并生成 Radar Issue 文案。
---

# 飞书生态雷达维护 Skill

用于维护 `/home/ubuntu/projects/lark-radar` 项目。

## 核心原则

1. **不要编造**：Radar 中的 commit、PR、Issue、Stars、最后更新时间必须来自真实 GitHub 数据。
2. **不要 clone 仓库**：只有明确需要代码级分析时才 clone；日常 Radar 扫描绝不 clone。
3. **GitHub 数据唯一入口**：日常 Radar 数据必须只通过 `scripts/lark-radar-scan.sh` 获取；不得在工作流中临时手写 `gh api`、GraphQL、curl 或其他 GitHub 查询来补数据。`gh api` 只能封装在扫描脚本内部使用。
4. **项目列表唯一来源**：读取 `projects.md`，不要在脚本或回答里写死项目清单。
5. **状态实时判断**：active / dormant / candidate 不手动维护，由扫描结果判断。
6. **脚本失败处理**：如果扫描输出截断、失败、字段不够或 JSON 过大导致错误，必须修复/增强 `scripts/lark-radar-scan.sh` 并重跑脚本；不得绕过脚本另写临时 GitHub 查询。
7. **Radar Issue 发布流程**：生成正式 GitHub Issue 前，先把报告写到本地 `reports/*.md` 草稿文件；该目录不提交到仓库；再用 `gh issue create --title "🛰️ 飞书生态开源项目雷达 · YYYY-MM-DD" --body-file <草稿文件>` 从文件发布，Issue 标题本身必须带卫星 emoji。
8. **输出风格参考**：`references/radar-issue-example.md`，但必须使用最新扫描数据，不可照抄旧数据。

## 常用路径

```text
/home/ubuntu/projects/lark-radar/
  README.md
  projects.md
  scripts/lark-radar-scan.sh
  references/radar-issue-example.md
  skills/lark-radar/SKILL.md
```

## 数据获取

### GitHub

**唯一允许的数据获取入口是扫描脚本**：

```bash
/home/ubuntu/projects/lark-radar/scripts/lark-radar-scan.sh --since YYYY-MM-DD --output /home/ubuntu/projects/lark-radar/reports/scan-YYYY-MM-DD.json
```

硬规则：

- 日常 Radar 工作流中，不得直接运行临时 `gh api`、GraphQL、curl 或其他 GitHub 查询来补数据。
- `gh api` 只能出现在 `scripts/lark-radar-scan.sh` 内部。
- 必须优先使用 `--output` 写入 `reports/scan-YYYY-MM-DD.json`，避免 stdout 截断或上下文丢失。
- 如果扫描结果缺字段、输出截断、JSON 太大、脚本报错，必须修复/增强扫描脚本后重跑；不得绕过脚本查询 GitHub。

### 飞书文档

如需读取飞书文档，必须用 lark-cli，不要用 web_fetch：

```bash
lark-cli docs +fetch --api-version v2 --doc "URL" --doc-format markdown
```

注意：lark-cli 配置目录 `~/.lark-cli` 在 bash sandbox 下不可见，运行 lark-cli 时使用 full_access。

## Radar Issue 推荐结构

1. 本期速览
   - 用一段话概括本期主要变化
   - 列出最活跃项目和关键趋势
2. 各项目进展
   - 只写本期有实质活动的项目
   - 每个项目用 Markdown link
   - 使用真实 commit / PR / issue 链接
3. 社区热点分析
   - 从多个项目的真实动态中归纳趋势
   - 不要写空泛判断
4. 雷达总表
   - 列出所有追踪项目
   - 包含 Stars、本周动态、方向
5. 休眠观察
   - 根据 pushed_at 自动判断超过 3 个月未更新的项目
6. 固定署名
   - 每份报告末尾必须添加：`Made by [Pokoclaw](https://github.com/danielwpz/pokoclaw) with love 💜`

## 状态标记建议

- 🔥：观察窗口内有 commit
- 📋：观察窗口内无 commit，但有 PR / Issue 更新
- 💤：观察窗口内无明显活动
- ⚠️：超过 2 个月无 push，接近休眠
- 休眠观察：超过 3 个月无 push

## 扫描脚本要求

`scripts/lark-radar-scan.sh` 应当：

1. 从 `projects.md` 解析 GitHub repo
2. 脚本内部可以使用 `gh api` 获取数据；工作流外层不得直接调用 `gh api`
3. 对单个项目失败做容错，不影响其他项目
4. 支持未来 100~200 个项目顺序扫描
5. 不把项目列表写死在脚本里
6. 输出结构化 JSON；支持 `--output FILE` 写文件，进度信息到 stderr
7. 大 JSON 必须通过临时文件 / `jq --slurpfile` 等方式处理，避免 `Argument list too long`
8. 脚本是唯一 GitHub 数据入口；新数据需求先增强脚本参数或输出字段，不得在工作流里另写临时查询

## 写作要求

- 简洁，但不能过度简化
- 每个项目名都使用 Markdown link
- 本期速览要有判断，但必须由数据支撑
- 社区热点分析要基于真实 PR / Issue / Commit
- 不要使用“可能”“应该”等没有数据支撑的推断过多
- 不要生成不存在的版本、PR、Issue 或趋势
- 报告末尾必须保留署名：`Made by [Pokoclaw](https://github.com/danielwpz/pokoclaw) with love 💜`
