#!/usr/bin/env bash
# 三省六部 · Docker 快速部署脚本

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  🐳 三省六部 Docker 部署工具            ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装${NC}"
        echo "请先安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker 未运行${NC}"
        echo "请启动 Docker 服务"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker 已就绪${NC}"
}

# 构建镜像
build_image() {
    echo ""
    echo "🔨 构建 Docker 镜像..."
    docker build -t edict-dashboard-api:latest .
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 启动服务
start_service() {
    echo ""
    echo "🚀 启动服务..."
    
    # 检查是否已运行
    if docker ps -a --format '{{.Names}}' | grep -q '^edict-api$'; then
        echo "⚠️  检测到已存在的容器，正在停止..."
        docker stop edict-api 2>/dev/null || true
        docker rm edict-api 2>/dev/null || true
    fi
    
    # 创建数据目录
    mkdir -p ./dashboard/data
    
    # 启动容器
    docker run -d \
        -p 7891:7891 \
        -v "$(pwd)/dashboard/data:/app/data:ro" \
        --name edict-api \
        --restart unless-stopped \
        edict-dashboard-api:latest
    
    echo -e "${GREEN}✅ 服务已启动${NC}"
}

# 显示状态
show_status() {
    echo ""
    echo "📊 服务状态:"
    docker ps --filter "name=edict-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "🌐 访问地址:"
    echo "   http://localhost:7891"
    echo ""
    echo "📋 API 测试:"
    echo "   curl http://localhost:7891/api/live-status"
    echo ""
}

# 停止服务
stop_service() {
    echo ""
    echo "🛑 停止服务..."
    docker stop edict-api 2>/dev/null || true
    docker rm edict-api 2>/dev/null || true
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 查看日志
show_logs() {
    echo ""
    echo "📜 实时日志 (Ctrl+C 退出):"
    docker logs -f edict-api
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            check_docker
            build_image
            start_service
            show_status
            ;;
        stop)
            stop_service
            ;;
        restart)
            stop_service
            build_image
            start_service
            show_status
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        build)
            check_docker
            build_image
            ;;
        *)
            echo "用法：$0 {start|stop|restart|logs|status|build}"
            echo ""
            echo "命令说明:"
            echo "  start   - 构建并启动服务"
            echo "  stop    - 停止服务"
            echo "  restart - 重启服务"
            echo "  logs    - 查看日志"
            echo "  status  - 查看状态"
            echo "  build   - 仅构建镜像"
            exit 1
            ;;
    esac
}

main "$@"
