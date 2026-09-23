# umaai_review · 赛马娘单局复盘 skill

把 `logs/game*.zip` 复盘成一份叙事性结论 + 一份网页报告：总体表现、运气走势与极值回合、
继承质量、坏手法、执行偏离。

**计算全部下沉到 Rust**（`bin/umaai_review.exe`），skill 只负责把事实叙述成人话。

## 安装

```powershell
# ① 装到你的 agent 工具 skills 目录（路径按你的工具改）
.\install.ps1 -SkillsDir C:\Users\<你>\.trae-cn\skills -UmaaiRoot <你的 umaai 目录>
```

`-UmaaiRoot` 指向 umaai 仓库（含 `gamedata/` 与 `logs/`）。不指定也可以，
首次复盘时 skill 会问你一次并记住。

安装后目录长这样：

```
<skills>\umaai_review\
├── SKILL.md            技能入口
├── reference/          判据与口径（含 pitfalls、马娘专属判据）
├── bin/umaai_review.exe
├── templates/          brief.md / report.html 模板
└── local_paths.json    {"umaai_root": "..."}   ← install 生成
```

## 怎么用

直接跟 agent 说「复盘一下这一局」「分析 game1430」即可。局包来源按三级优先：

| 优先 | 来源 |
|---|---|
| ① | 直接拖进对话的文件 |
| ② | 你给的路径（任意位置） |
| ③ | `<umaai_root>/logs/` 下最新的 `game*.zip` |

产物落在**当前工作区** `<cwd>/game{id}/`：`brief.md`（事实简报）、`digest.json`（完整数据）、
`report.html`（网页报告）。

## gamedata 与「旧版数据」

gamedata 只按 umaai 目录解析：`<umaai_root>/gamedata`。
**没有 umaai 目录时**，用本仓自带的 `gamedata/`——此时 bin 会在结论里标注
「gamedata 为 skill 自带旧版」，因为卡名 / 赛程 / 地区名会随游戏版本过期。

要让自带数据保持新鲜，维护者更新时：

```powershell
Copy-Item <umaai>\gamedata .\gamedata -Recurse -Force
"v<版本> / 打包于 $(Get-Date -Format yyyy-MM-dd)" | Set-Content .\gamedata\BUNDLED
```

`gamedata/` 默认**不随仓发布**（避免分发游戏数据）；需要时手动放入并在发布包里带上。

## 维护者：本仓是生成物

**`umaai-rs` 是唯一源**，本仓的文件由脚本单向生成，不要在这里直接改：

```powershell
.\sync.ps1              # 从 umaai-rs 同步进来
.\sync.ps1 -Check       # 只校验一致性（发版前 / CI）
```

被同步的内容：`SKILL.md`、`reference/`、`templates/`、`bin/umaai_review.exe`。
本仓独有的：`README.md`、`install.ps1`、`sync.ps1`。

## 环境要求

- Windows x64（`bin/umaai_review.exe` 为预编译二进制）
- 复盘时需要 Python 或 PowerShell 之一（skill 内部取数用，优先 Python）

## 已知限制

- 二进制平台绑定 Windows x64；其他平台需自行从 umaai-rs 编译 `umaai_review`
- 一批判据仍在实测标定中（体力健康、吃面节奏、友人完成度等），
  见 `reference/metrics_glossary.md` 与 `reference/pitfalls.md`
- 部分归因口径依赖真实局包实测，细节以 `reference/` 为准
