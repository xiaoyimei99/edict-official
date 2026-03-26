# 三省六部 · Edict Dashboard API
# 极简后端 - 只提供数据读取 API

FROM python:3.11-slim

WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建目录结构
RUN mkdir -p /app/scripts /app/data /app/dashboard

# 复制必要的脚本文件
COPY scripts/file_lock.py ./scripts/
COPY scripts/utils.py ./scripts/

# 复制数据目录
COPY dashboard/data/ ./data/

# 复制服务器脚本
COPY dashboard/server.py ./

# 暴露端口
EXPOSE 7891

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7891/healthz || exit 1

# 启动命令
CMD ["python", "server.py", "--port", "7891", "--host", "0.0.0.0"]
