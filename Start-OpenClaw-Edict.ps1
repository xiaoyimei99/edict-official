# ══════════════════════════════════════════════════════════════
# 三省六部 · OpenClaw Multi-Agent System 启动脚本 (Windows)
# PowerShell 版本
# ══════════════════════════════════════════════════════════════
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$REPO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OC_HOME = Join-Path $env:USERPROFILE ".openclaw"

function Write-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  🏛️  三省六部 · OpenClaw Multi-Agent     ║" -ForegroundColor Blue
    Write-Host "║          启动脚本 (Windows)              ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Log   { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Warn  { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Info  { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Blue }

Write-Banner

# ── Step 1: 启动 OpenClaw 网关 ──
Info "启动 OpenClaw 网关..."
try {
    Start-Process -FilePath "openclaw" -ArgumentList "gateway" -NoNewWindow -PassThru
    Log "OpenClaw 网关已启动"
} catch {
    Error "启动 OpenClaw 网关失败: $($_.Exception.Message)"
    exit 1
}

Start-Sleep -Seconds 5

# ── Step 2: 启动三省六部总控台 ──
Info "启动三省六部总控台..."
try {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        $python = Get-Command python3 -ErrorAction SilentlyContinue
    }
    if (-not $python) {
        Error "未找到 python 或 python3"
        exit 1
    }
    
    $dashboard_server = Join-Path $REPO_DIR "dashboard" "server.py"
    Start-Process -FilePath $python.Source -ArgumentList @($dashboard_server, "--port", "7891") -NoNewWindow -PassThru
    Log "三省六部总控台已启动 → http://127.0.0.1:7891"
} catch {
    Error "启动三省六部总控台失败: $($_.Exception.Message)"
    exit 1
}

Start-Sleep -Seconds 3

# ── Step 3: 同步数据 ──
Info "同步数据..."
try {
    $sync_script = Join-Path $REPO_DIR "scripts" "sync_from_openclaw_runtime.py"
    & $python.Source $sync_script
    Log "数据同步完成"
    
    $refresh_script = Join-Path $REPO_DIR "scripts" "refresh_live_data.py"
    & $python.Source $refresh_script
    Log "实时数据刷新完成"
} catch {
    Warn "数据同步失败: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🏛️  三省六部系统启动完成！              ║" -ForegroundColor Green
Write-Host "║  访问地址: http://127.0.0.1:7891        ║" -ForegroundColor Green
Write-Host "║  按 Ctrl+C 停止所有服务                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# 保持脚本运行
while ($true) {
    Start-Sleep -Seconds 1
}