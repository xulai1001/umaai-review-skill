# 把本 skill 安装到 agent 工具的 skills 目录
#
# 用法：
#   .\install.ps1 -SkillsDir <agent 工具 skills 目录>              # 只装 skill
#   .\install.ps1 -SkillsDir <agent 工具 skills 目录> -UmaaiRoot <umaai 目录>
#                                                                  # 同时写入 umaai 目录配置
param(
    [Parameter(Mandatory = $true)][string]$SkillsDir,
    [string]$UmaaiRoot = ''
)

$ErrorActionPreference = 'Stop'
$dst = Join-Path $SkillsDir 'umaai_review'

New-Item -ItemType Directory -Force -Path $dst | Out-Null
foreach ($item in 'SKILL.md', 'reference', 'templates', 'bin') {
    $src = Join-Path $PSScriptRoot $item
    if (Test-Path $src) { Copy-Item $src $dst -Recurse -Force }
}
# 可选：随包携带的 gamedata（会被 bin 标为「旧版数据」）
$gd = Join-Path $PSScriptRoot 'gamedata'
if (Test-Path $gd) {
    Copy-Item $gd $dst -Recurse -Force
    Write-Host '已随包装入 gamedata（bin 会标为旧版数据）' -ForegroundColor Yellow
}
Write-Host "已安装到 $dst" -ForegroundColor Green

if ($UmaaiRoot) {
    $gdPath = Join-Path $UmaaiRoot 'gamedata'
    if (-not (Test-Path (Join-Path $gdPath 'umaDB.json'))) {
        Write-Host "警告：$gdPath 下没有 umaDB.json，可能不是 umaai 目录" -ForegroundColor Yellow
    }
    $json = '{' + "`n  `"umaai_root`": `"$($UmaaiRoot -replace '\\', '/')`"`n" + '}'
    # 不用 Set-Content -Encoding UTF8（PowerShell 5.1 会写 BOM，破坏 JSON 解析）
    [System.IO.File]::WriteAllText((Join-Path $dst 'local_paths.json'), $json)
    Write-Host "已写入 local_paths.json（umaai_root = $UmaaiRoot）" -ForegroundColor Green
} else {
    Write-Host '未指定 -UmaaiRoot：首次复盘时会询问 umaai 目录在哪' -ForegroundColor Yellow
}
