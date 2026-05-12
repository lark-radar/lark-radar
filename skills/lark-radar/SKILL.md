---
name: lark-radar
version: 0.1.0
description: 维护飞书 / Lark 开源生态项目雷达，扫描 GitHub 项目并生成 Radar Issue 文案。
---

# 飞书生态雷达维护 Skill

用于维护 `/home/ubuntu/projects/lark-radar` 项目。

## 核心原则

1. **不要编造**：Radar 中的 commit、PR、Issue、Stars、最后更新时间必须来自真实 GitHub 数据。
2. **不要 clone 仓库**：默认用 `gh api` 获取数据；只有明确需要代码级分析时才 clone。
3. **项目列表唯一来源**：读取 `projects.md`，不要在脚本或回答里写死项目清单。
4. **状态实时判断**：active / dormant / candidate 不手动维护，由扫描结果判断。
5. **Radar Issue 发布流程**：生成正式 GitHub Issue 前，先把报告写到本地 `reports/*.md` 草稿文件；该目录不提交到仓库；再用 `gh issue create --body-file` 从文件发布。
6. **输出风格参考**：`references/radar-issue-example.md`，但必须使用最新扫描数据，不可照抄旧数据。

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

使用 `gh api`，当前环境已登录 GitHub 用户。运行扫描脚本：

```bash
/home/ubuntu/projects/lark-radar/scripts/lark-radar-scan.sh --since YYYY-MM-DD
```

脚本输出 JSON 到 stdout。

### 飞书文档

如需读取飞书文档，必须用 lark-cli，不要用 web_fetch：

```bash
lark-cli docs +fetch --api-version v2 --doc "URL" --doc-format markdown
```

注意：lark-cli 配置目录 `~/.lark-cli` 在 bash sandbox 下不可见，运行 lark-cli 时使用 full_access。

## Radar Issue 推荐结构

1. 今日速览
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
2. 使用 `gh api` 获取数据
3. 对单个项目失败做容错，不影响其他项目
4. 支持未来 100~200 个项目顺序扫描
5. 不把项目列表写死在脚本里
6. 输出结构化 JSON 到 stdout，进度信息到 stderr

## 写作要求

- 简洁，但不能过度简化
- 每个项目名都使用 Markdown link
- 今日速览要有判断，但必须由数据支撑
- 社区热点分析要基于真实 PR / Issue / Commit
- 不要使用“可能”“应该”等没有数据支撑的推断过多
- 不要生成不存在的版本、PR、Issue 或趋势
- 报告末尾必须保留署名：`Made by [Pokoclaw](https://github.com/danielwpz/pokoclaw) with love 💜`
