# Docker 构建
docker build -t edict-api:latest .

# 启动服务（生产模式）
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
