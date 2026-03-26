# 🐳 Docker 部署指南

## 快速开始

### 本地测试

```bash
# 1. 构建镜像
docker build -t edict-dashboard-api .

# 2. 运行容器
docker run -d -p 7891:7891 \
  -v $(pwd)/dashboard/data:/app/data:ro \
  --name edict-api \
  edict-dashboard-api

# 3. 访问 API
# http://localhost:7891
```

### 使用 Docker Compose

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## GitHub Actions 自动部署

### 配置步骤

1. **Fork 仓库到 GitHub**
   ```bash
   git remote add github https://github.com/YOUR_USERNAME/edict-official.git
   ```

2. **推送到 GitHub**
   ```bash
   git push github main
   ```

3. **GitHub Actions 会自动构建**
   - 推送到 `main` 分支 → 构建 `latest` 标签
   - 创建 `v1.2.3` 标签 → 构建对应版本标签

4. **获取镜像**
   ```bash
   docker pull ghcr.io/YOUR_USERNAME/edict-official:latest
   ```

---

## 部署到服务器

### VPS / 云主机

```bash
# 1. 拉取镜像
docker pull ghcr.io/YOUR_USERNAME/edict-official:latest

# 2. 运行容器
docker run -d -p 7891:7891 \
  -v /path/to/data:/app/data:ro \
  --restart unless-stopped \
  --name edict-api \
  ghcr.io/YOUR_USERNAME/edict-official:latest
```

### 树莓派

```bash
# 镜像支持 ARM64 架构，可以直接运行
docker pull ghcr.io/YOUR_USERNAME/edict-official:latest

docker run -d -p 7891:7891 \
  -v /home/pi/edict/data:/app/data:ro \
  --restart unless-stopped \
  --name edict-api \
  ghcr.io/YOUR_USERNAME/edict-official:latest
```

---

## 数据持久化

### 挂载数据目录

```bash
docker run -d -p 7891:7891 \
  -v /host/path/to/data:/app/data:ro \
  edict-dashboard-api
```

### 数据文件位置

```
dashboard/data/
├── live_status.json       # 实时任务状态
├── agent_config.json      # Agent 配置
├── officials_stats.json   # 官员统计
├── model_change_log.json  # 模型变更日志
└── ...
```

---

## 健康检查

```bash
# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' edict-api

# 手动测试 API
curl http://localhost:7891/healthz
curl http://localhost:7891/api/live-status
```

---

## 日志查看

```bash
# 查看实时日志
docker logs -f edict-api

# 查看最近 100 行
docker logs --tail 100 edict-api

# 查看特定时间
docker logs --since 2026-03-26T20:00:00 edict-api
```

---

## 更新镜像

```bash
# 拉取最新镜像
docker pull ghcr.io/YOUR_USERNAME/edict-official:latest

# 停止旧容器
docker stop edict-api
docker rm edict-api

# 启动新容器
docker run -d -p 7891:7891 \
  -v /path/to/data:/app/data:ro \
  --restart unless-stopped \
  --name edict-api \
  ghcr.io/YOUR_USERNAME/edict-official:latest
```

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PYTHONUNBUFFERED` | `1` | 禁用 Python 缓冲 |
| `PYTHONDONTWRITEBYTECODE` | `1` | 不生成 .pyc 文件 |

---

## 故障排查

### 容器无法启动

```bash
# 查看错误日志
docker logs edict-api

# 进入容器调试
docker run -it --entrypoint /bin/sh edict-dashboard-api
```

### 数据不更新

确保数据目录挂载正确：
```bash
docker inspect edict-api | grep -A 10 Mounts
```

### 端口冲突

修改映射端口：
```bash
docker run -d -p 8080:7891 edict-dashboard-api
# 访问 http://localhost:8080
```

---

## 安全建议

1. **只读挂载数据**：使用 `:ro` 标志防止意外修改
2. **限制资源**：使用 `--memory` 和 `--cpus` 限制资源使用
3. **定期更新**：保持镜像最新，获取安全补丁
4. **网络隔离**：使用 Docker 网络隔离容器

```bash
# 限制资源示例
docker run -d -p 7891:7891 \
  --memory="512m" \
  --cpus="1.0" \
  edict-dashboard-api
```

---

## 性能优化

### 多阶段构建（可选）

如果需要更小的镜像，可以使用多阶段构建：

```dockerfile
FROM python:3.11-slim as builder
# ... 构建步骤 ...

FROM python:3.11-alpine
COPY --from=builder /app /app
CMD ["python", "server.py", "--port", "7891"]
```

### 使用 Alpine 基础镜像

```dockerfile
FROM python:3.11-alpine
# 镜像大小约 50MB（vs slim 约 120MB）
```

---

## 许可证

MIT License - 可自由使用、修改、分发
