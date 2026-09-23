# 单向同步：umaai-rs（唯一源）→ 本仓
#
# 用法：
#   .\sync.ps1 -UmaaiRoot <umaai-rs 目录>   # 指定源
#   .\sync.ps1                             # 省略时读本仓 local_paths.json（不入库）
#   .\sync.ps1 -Check                      # 只校验一致性，不写入（CI / 发版前用）
param(
    [string]$UmaaiRoot = '',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$dst = $PSScriptRoot

# 未显式指定时，回退读 local_paths.json（机器相关，不入版本控制）
if (-not $UmaaiRoot) {
    $lp = Join-Path $dst 'local_paths.json'
    if (Test-Path $lp) {
        $UmaaiRoot = (Get-Content $lp -Raw -Encoding UTF8 | ConvertFrom-Json).umaai_root
    }
}
if (-not $UmaaiRoot) {
    Write-Host '请用 -UmaaiRoot 指定 umaai-rs 目录，或先写 local_paths.json' -ForegroundColor Yellow
    exit 1
}
Write-Host "源: $UmaaiRoot"

$map = @(
    @{ Src = "$UmaaiRoot\.trae\skills\umaai_review\SKILL.md";   Dst = "$dst\SKILL.md" },
    @{ Src = "$UmaaiRoot\.trae\skills\umaai_review\reference"; Dst = "$dst\reference"; Dir = $true },
    @{ Src = "$UmaaiRoot\crates\umaai_review\templates";       Dst = "$dst\templates"; Dir = $true },
    @{ Src = "$UmaaiRoot\target\release\umaai_review.exe";     Dst = "$dst\bin\umaai_review.exe" }
)

function Get-Sha([string]$p) { (Get-FileHash $p -Algorithm SHA256).Hash }

$bad = 0
foreach ($m in $map) {
    if (-not (Test-Path $m.Src)) {
        Write-Host "源不存在: $($m.Src)" -ForegroundColor Yellow
        $bad++
        continue
    }
    if ($m.Dir) {
        Get-ChildItem $m.Src -File | ForEach-Object {
            $t = Join-Path $m.Dst $_.Name
            if ($Check) {
                if (-not (Test-Path $t)) { Write-Host "缺失: $($_.Name)"; $bad++ }
                elseif ((Get-Sha $_.FullName) -ne (Get-Sha $t)) { Write-Host "不一致: $($_.Name)"; $bad++ }
            } else {
                Copy-Item $_.FullName $t -Force
                Write-Host "同步: $($_.Name)"
            }
        }
    } else {
        if ($Check) {
            if (-not (Test-Path $m.Dst)) { Write-Host "缺失: $($m.Dst)"; $bad++ }
            elseif ((Get-Sha $m.Src) -ne (Get-Sha $m.Dst)) { Write-Host "不一致: $($m.Dst)"; $bad++ }
        } else {
            Copy-Item $m.Src $m.Dst -Force
            Write-Host "同步: $($m.Dst)"
        }
    }
}

if ($Check) {
    if ($bad -eq 0) { Write-Host "`n一致性校验通过：本仓与 umaai-rs 同源" -ForegroundColor Green }
    else { Write-Host "`n$bad 项不一致/缺失——请先跑 .\sync.ps1" -ForegroundColor Yellow; exit 1 }
} else {
    Write-Host "`n同步完成（umaai-rs 为唯一源；改 skill 请改 umaai-rs 侧再同步）" -ForegroundColor Green
}
