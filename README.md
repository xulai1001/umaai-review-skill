# umaai_review · 赛马娘单局复盘 skill

把 `logs/game*.zip` 复盘成一份叙事性结论 + 一份网页报告：总体表现、运气走势与极值回合、
继承质量、坏手法、执行偏离。

**计算全部下沉到 Rust**（`bin/umaai_review.exe`），skill 只负责把事实叙述成人话。

## 安装

> 下文 `<owner>/<repo>` 请替换为实际仓库地址。

### 方式 A：下载 Release 包（推荐，agent 也能照做）

```powershell
$url = 'https://github.com/<owner>/<repo>/releases/latest/download/umaai_review.zip'
Invoke-WebRequest $url -OutFile umaai_review.zip
Expand-Archive umaai_review.zip -DestinationPath <你的 agent 工具 skills 目录> -Force
Remove-Item umaai_review.zip
```

包内顶层目录就是 skill 目录名，**解压即到位**，不用改名。

**给 agent 的安装指令**（可机械照做）：

1. 确定目标：`<skills 目录>/umaai_review`——`<skills 目录>` 优先用户指定，
   否则用你所在工具的 skills 目录（如 `<工作区>/.trae/skills`、`~/.trae-cn/skills`、`~/.claude/skills`）
2. 下载上面的 zip，解压到 `<skills 目录>`（得到 `<skills 目录>/umaai_review/`）
3. 配置 umaai 目录：写 `<skills 目录>/umaai_review/local_paths.json`，
   内容 `{"umaai_root": "<umaai 目录>"}`；不确定就跳过——首次复盘时会问用户
4. 自检：`<skills 目录>/umaai_review/bin/umaai_review.exe --help` 应打印用法

### 方式 B：克隆仓库（可 `git pull` 升级）

```powershell
git clone <repo-url> <你的 agent 工具 skills 目录>/umaai_review
```

目录名必须显式写成 `umaai_review`（仓库名与 skill 名不同）。

### 方式 C：用仓内安装脚本

```powershell
.\install.ps1 -SkillsDir <你的 agent 工具 skills 目录> -UmaaiRoot <你的 umaai 目录>
```

`-UmaaiRoot` 指向 umaai 仓库（含 `gamedata/` 与 `logs/`）。不指定也可以，
首次复盘时 skill 会问你一次并记住。

### 安装后的目录

```
<skills>/umaai_review/
├── SKILL.md            技能入口
├── reference/          判据与口径（含 pitfalls、马娘专属判据）
├── templates/          brief.md / report.html 模板
├── bin/umaai_review.exe
└── local_paths.json    {"umaai_root": "..."}   ← 可选
```

### 升级

- 方式 A：重新下载解压覆盖（`local_paths.json` 不在包里，会**保留**）
- 方式 B：在 skill 目录里 `git pull`

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

gamedata 按两级解析：

```
<umaai_root>/gamedata          ← 装了 umaai 就用这份（最新）
  ↓ 没有 umaai_root / 该目录不存在
<skill>/data/gamedata/         ← skill 自带，随 Release 包发布
```

用自带那份时，bin 会在结论里标注「gamedata 为 skill 自带旧版（版本）」——
卡名 / 赛程 / 地区名会随游戏版本过期，症状与应对见下。

**自带那份放在 `data/` 下**（bin 要求目录名必须是 `gamedata`，但位置任意），
所以升级覆盖解压**不会动到你自己放的 `<skill>/gamedata/`**。
想用更新的数据，把 umaai 的 `gamedata/` 拷到 skill 根下的 `gamedata/` 即可（优先级更高）。

### 数据过期会怎样

| 过期项 | 症状 |
|---|---|
| umaDB（马娘赛程） | 养新马娘时旧库没有她的赛程 → 赛程与评分不可用 |
| races（必赛回合） | 必赛判定错 → 误报「目标赛未跑赢」 |
| cardDB（卡名/类型） | 卡组显示 `unknown(<id>)` |
| text_data_dict | 技能名、事件名显示旧称 |

维护者刷数据：跑 `.\sync.ps1` 会自动从 umaai 目录拷到 `gamedata-bundled/`，
并写入 `BUNDLED`（打包日期 + umaai-rs 提交号）。

## 维护者：本仓是生成物

**`umaai-rs` 是唯一源**，本仓的文件由脚本单向生成，不要在这里直接改：

```powershell
.\sync.ps1 -UmaaiRoot <umaai-rs 目录>   # 从 umaai-rs 同步进来
.\sync.ps1                              # 省略 -UmaaiRoot 时读本仓 local_paths.json
.\sync.ps1 -Check                       # 只校验一致性（发版前 / CI）
```

被同步的内容：`SKILL.md`、`reference/`、`templates/`、`bin/umaai_review.exe`。
本仓独有的：`README.md`、`install.ps1`、`sync.ps1`、`.github/workflows/release.yml`。

### 发版

**本机不需要 `gh`** —— 打 tag 推上去，GitHub Actions 自动打包并创建 Release：

```powershell
.\sync.ps1 -Check          # 先确认与 umaai-rs 同源（CI 访问不到该源仓，只能本地校验）
git tag v1.0.0
git push origin v1.0.0
```

产物：Release 附件 `umaai_review.zip`（内含顶层目录 `umaai_review/`）。
稳定链接 `…/releases/latest/download/umaai_review.zip` 永远指向最新版。

## 素材来源

- 报告背景图：pixiv id **148120780**

## 环境要求

- Windows x64（`bin/umaai_review.exe` 为预编译二进制）
- 复盘时需要 Python 或 PowerShell 之一（skill 内部取数用，优先 Python）

## 已知限制

- 二进制平台绑定 Windows x64；其他平台需自行从 umaai-rs 编译 `umaai_review`
- 一批判据仍在实测标定中（体力健康、吃面节奏、友人完成度等），
  见 `reference/metrics_glossary.md` 与 `reference/pitfalls.md`
- 部分归因口径依赖真实局包实测，细节以 `reference/` 为准
