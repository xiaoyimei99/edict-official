#!/usr/bin/env pwsh
# GitHub 自动配置脚本

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub 配置助手                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查 Git
Write-Host " 检查 Git 安装..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git 已安装：$gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git 未安装！" -ForegroundColor Red
    Write-Host "请前往 https://git-scm.com/download/win 下载安装" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 检查是否已配置
Write-Host "📌 检查 Git 配置..." -ForegroundColor Yellow
$username = git config --global user.name
$email = git config --global user.email

if ($username -and $email) {
    Write-Host "✅ Git 已配置:" -ForegroundColor Green
    Write-Host "   用户名：$username" -ForegroundColor Gray
    Write-Host "   邮箱：$email" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Git 未配置，需要设置" -ForegroundColor Yellow
    Write-Host ""
    
    # 获取用户信息
    if (-not $username) {
        $username = Read-Host "请输入你的 GitHub 用户名"
        git config --global user.name $username
        Write-Host "✅ 用户名已设置：$username" -ForegroundColor Green
    }
    
    if (-not $email) {
        Write-Host ""
        Write-Host "邮箱格式：yourname@users.noreply.github.com" -ForegroundColor Gray
        $email = Read-Host "请输入你的 GitHub 邮箱"
        git config --global user.email $email
        Write-Host "✅ 邮箱已设置：$email" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 检查是否已初始化 Git 仓库
Write-Host "📌 检查 Git 仓库状态..." -ForegroundColor Yellow
$gitDir = Join-Path $PSScriptRoot ".git"

if (Test-Path $gitDir) {
    Write-Host "✅ Git 仓库已初始化" -ForegroundColor Green
    
    # 检查远程仓库
    $remote = git remote get-url origin 2>$null
    if ($remote) {
        Write-Host "✅ 远程仓库已配置：$remote" -ForegroundColor Green
    } else {
        Write-Host "⚠️  未配置远程仓库" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "请按以下步骤操作：" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. 访问 https://github.com/new 创建新仓库" -ForegroundColor White
        Write-Host "2. 仓库名：edict-official" -ForegroundColor White
        Write-Host "3. 选择 Public 或 Private" -ForegroundColor White
        Write-Host "4. 不要勾选 'Add a README file'" -ForegroundColor White
        Write-Host "5. 复制仓库地址，然后运行：" -ForegroundColor White
        Write-Host ""
        Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/edict-official.git" -ForegroundColor Cyan
        Write-Host ""
    }
} else {
    Write-Host "⚠️  Git 仓库未初始化" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "正在初始化 Git 仓库..." -ForegroundColor Cyan
    
    Set-Location $PSScriptRoot
    git init
    Write-Host "✅ Git 仓库已初始化" -ForegroundColor Green
    
    # 创建 .gitignore
    $gitignorePath = Join-Path $PSScriptRoot ".gitignore"
    if (-not (Test-Path $gitignorePath)) {
        @"
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/
dist/
build/

# Node
node_modules/
npm-debug.log
yarn-error.log

# 数据文件
dashboard/data/*.json
!dashboard/data/.gitkeep

# 日志
*.log

# 环境
.env
.env.*

# 系统文件
.DS_Store
Thumbs.db
"@ | Out-File -FilePath $gitignorePath -Encoding utf8
        Write-Host "✅ .gitignore 已创建" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📦 正在添加所有文件..." -ForegroundColor Yellow
    git add .
    
    Write-Host ""
    Write-Host "📦 正在提交..." -ForegroundColor Yellow
    git commit -m "Initial commit: 三省六部 Docker 部署配置"
    Write-Host "✅ 首次提交完成" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步操作：" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 创建 GitHub 仓库：" -ForegroundColor White
    Write-Host "   访问 https://github.com/new" -ForegroundColor Gray
    Write-Host "   仓库名：edict-official" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 添加远程仓库并推送：" -ForegroundColor White
    Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/edict-official.git" -ForegroundColor Cyan
    Write-Host "   git push -u origin main" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 检查 GitHub CLI
Write-Host "📌 检查 GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = gh --version 2>$null
    if ($ghVersion) {
        Write-Host "✅ GitHub CLI 已安装" -ForegroundColor Green
        Write-Host ""
        
        # 检查是否已登录
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in to github.com") {
            Write-Host "✅ 已登录 GitHub" -ForegroundColor Green
        } else {
            Write-Host "⚠️  未登录 GitHub，是否现在登录？" -ForegroundColor Yellow
            $login = Read-Host "登录 GitHub (y/n)"
            if ($login -eq 'y' -or $login -eq 'Y') {
                gh auth login
                Write-Host "✅ 登录成功" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "⚠️  GitHub CLI 未安装" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "可选安装（推荐）：" -ForegroundColor Cyan
        Write-Host "   winget install --id GitHub.cli" -ForegroundColor Gray
        Write-Host ""
        Write-Host "或者使用网页版：" -ForegroundColor Cyan
        Write-Host "   https://github.com" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  GitHub CLI 未安装" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 配置完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 如果还没创建 GitHub 仓库，请现在创建" -ForegroundColor White
Write-Host "2. 添加远程仓库并推送代码" -ForegroundColor White
Write-Host "3. 启用 GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "详细指南请查看：GITHUB_SETUP.md" -ForegroundColor Yellow
Write-Host ""
