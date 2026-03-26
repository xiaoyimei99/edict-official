# 🔐 GitHub 配置指南

## 前提条件

你需要：
1. ✅ 一个 GitHub 账号（如果没有，访问 https://github.com/signup 注册）
2. ✅ Git 已安装（已确认：v2.53.0）
3. ❌ 需要配置 Git 用户信息
4. ❌ 需要将代码推送到 GitHub

---

## 方案 A：使用 GitHub Desktop（最简单，推荐新手）

### 步骤 1：下载 GitHub Desktop

访问：https://desktop.github.com/

### 步骤 2：安装并登录

1. 安装 GitHub Desktop
2. 使用 GitHub 账号登录
3. 它会自动配置 Git

### 步骤 3：添加项目

1. 打开 GitHub Desktop
2. 选择 `File` → `Add Local Repository`
3. 选择 `edict-official` 目录
4. 点击 `Commit to main`
5. 点击 `Publish repository`

### 步骤 4：启用 GitHub Actions

1. 访问 https://github.com/YOUR_USERNAME/edict-official
2. 点击 `Settings` → `Actions` → `General`
3. 选择 `Allow all actions and reusable workflows`
4. 点击 `Save`

**完成！** 现在每次推送都会自动构建 Docker 镜像。

---

## 方案 B：使用命令行（推荐开发者）

### 步骤 1：配置 Git 用户信息

```bash
# 设置你的 GitHub 用户名
git config --global user.name "你的 GitHub 用户名"

# 设置你的邮箱（使用 GitHub 的邮箱）
git config --global user.email "你的邮箱@users.noreply.github.com"

# 验证配置
git config --global user.name
git config --global user.email
```

### 步骤 2：初始化 Git 仓库

```bash
cd c:\Users\drx\.openclaw\edict-official

# 初始化仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: 三省六部 Docker 部署配置"
```

### 步骤 3：创建 GitHub 仓库

**方法 1：使用 GitHub CLI（需要先安装）**

```bash
# 安装 GitHub CLI（如果未安装）
winget install --id GitHub.cli

# 登录 GitHub
gh auth login

# 创建仓库
gh repo create edict-official --public --source=. --remote=origin --push
```

**方法 2：手动创建（无需额外工具）**

1. 访问 https://github.com/new
2. 仓库名：`edict-official`
3. 选择 `Public` 或 `Private`
4. **不要**勾选 "Add a README file"
5. 点击 `Create repository`

然后复制仓库地址，执行：

```bash
# 添加远程仓库（替换 YOUR_USERNAME 为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/edict-official.git

# 推送到 GitHub
git push -u origin main
```

### 步骤 4：启用 GitHub Actions

1. 访问 https://github.com/YOUR_USERNAME/edict-official/actions
2. 点击 `I understand my workflows, go ahead and enable them`

---

## 方案 C：使用 Gitee（国内用户可选）

如果访问 GitHub 慢，可以使用 Gitee（码云）：

### 步骤

1. 访问 https://gitee.com/new 创建仓库
2. 仓库名：`edict-official`
3. 然后推送：

```bash
git remote add gitee https://gitee.com/YOUR_USERNAME/edict-official.git
git push -u gitee main
```

**注意**：Gitee 的 Actions 功能需要企业版，免费版可以使用 Gitee Go。

---

## 验证配置

### 检查 Git 配置

```bash
git config --global user.name
git config --global user.email
git remote -v
```

### 测试推送

```bash
# 修改任意文件
echo "# Test" >> README.md

# 提交并推送
git add .
git commit -m "Test commit"
git push

# 访问 GitHub 查看提交记录
# https://github.com/YOUR_USERNAME/edict-official/commits/main
```

### 检查 Actions 状态

1. 访问 https://github.com/YOUR_USERNAME/edict-official/actions
2. 应该能看到正在运行的工作流
3. 等待 2-3 分钟，查看是否成功构建 Docker 镜像

---

## 常见问题

### Q1: 推送时要求登录怎么办？

**Windows 用户**：
- 会弹出浏览器让你登录 GitHub
- 登录后授权即可

**或者使用 Personal Access Token**：
1. 访问 https://github.com/settings/tokens
2. 点击 `Generate new token (classic)`
3. 勾选 `repo` 权限
4. 复制生成的 token
5. 推送时使用：
   ```bash
   git push https://YOUR_USERNAME:TOKEN@github.com/YOUR_USERNAME/edict-official.git main
   ```

### Q2: Actions 没有自动触发？

检查：
1. ✅ 工作流文件是否在 `.github/workflows/` 目录
2. ✅ 分支名是否为 `main` 或 `master`
3. ✅ Actions 是否已启用（Settings → Actions）

### Q3: Docker 镜像构建失败？

查看日志：
1. 访问 https://github.com/YOUR_USERNAME/edict-official/actions
2. 点击失败的运行
3. 查看详细错误

常见原因：
- Dockerfile 路径错误
- 文件不存在
- 构建超时

---

## 下一步

配置完成后，执行：

```bash
# 提交所有文件
cd c:\Users\drx\.openclaw\edict-official
git add .
git commit -m "feat: 添加 Docker 部署配置"

# 推送到 GitHub
git push -u origin main

# 然后访问 GitHub 查看 Actions 运行
# https://github.com/YOUR_USERNAME/edict-official/actions
```

等待 2-3 分钟后，你就可以：

```bash
# 拉取自动构建的镜像
docker pull ghcr.io/YOUR_USERNAME/edict-official:latest

# 运行容器
docker run -d -p 7891:7891 \
  --name edict-api \
  ghcr.io/YOUR_USERNAME/edict-official:latest

# 访问 http://localhost:7891
```

---

## 需要帮助？

运行以下命令获取帮助：

```bash
# 检查 Git 配置
git config --list

# 检查远程仓库
git remote -v

# 查看提交历史
git log --oneline
```

或者访问：
- GitHub 文档：https://docs.github.com/
- Docker 文档：https://docs.docker.com/
