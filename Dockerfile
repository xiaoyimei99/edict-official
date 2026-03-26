# 三省六部 · Edict Dashboard API
# 极简后端 - 只提供数据读取 API

FROM python:3.11-slim

WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1

# 复制所有代码
COPY scripts/ ./scripts/
COPY dashboard/ ./dashboard/

# 暴露端口
EXPOSE 7891

# 启动命令
CMD ["python", "dashboard/server.py", "--port", "7891", "--host", "0.0.0.0"]
