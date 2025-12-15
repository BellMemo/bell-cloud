#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default installation directory
INSTALL_DIR="${1:-bell-cloud}"

# GitHub repository base URL
GITHUB_REPO="https://raw.githubusercontent.com/BellMemo/bell-cloud/main"

echo -e "${GREEN}🎐 Bell Cloud 一键安装脚本${NC}"
echo "=================================="

# Check dependencies
echo "检查依赖..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到 Docker，请先安装 Docker${NC}"
    echo "访问 https://docs.docker.com/get-docker/ 获取安装指南"
    exit 1
fi

# Check for Docker Compose V2 (docker compose) first, then fallback to V1 (docker-compose)
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: 未找到 Docker Compose${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker 已安装${NC}"

# Create installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}警告: 目录 '$INSTALL_DIR' 已存在${NC}"
    read -p "是否继续？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "创建项目目录: $(pwd)"

# Download docker-compose.yml from GitHub
echo "从 GitHub 下载配置文件..."
if curl -fsSL "$GITHUB_REPO/docker-compose.yml" -o docker-compose.yml; then
    echo -e "${GREEN}✓ 下载 docker-compose.yml${NC}"
else
    echo -e "${RED}错误: 无法从 GitHub 下载 docker-compose.yml${NC}"
    echo "请检查网络连接或访问: $GITHUB_REPO/docker-compose.yml"
    exit 1
fi

# Download init.sh from GitHub
if curl -fsSL "$GITHUB_REPO/init.sh" -o init.sh; then
    chmod +x init.sh
    echo -e "${GREEN}✓ 下载 init.sh${NC}"
else
    echo -e "${RED}错误: 无法从 GitHub 下载 init.sh${NC}"
    echo "请检查网络连接或访问: $GITHUB_REPO/init.sh"
    exit 1
fi

# Download .gitignore from GitHub
if curl -fsSL "$GITHUB_REPO/.gitignore" -o .gitignore; then
    echo -e "${GREEN}✓ 下载 .gitignore${NC}"
else
    echo -e "${YELLOW}警告: 无法从 GitHub 下载 .gitignore，将使用默认配置${NC}"
    cat > .gitignore <<'EOF'
# Alist data and storage
data/
storage/
.DS_Store
EOF
fi

echo ""
echo -e "${GREEN}安装完成！${NC}"
echo "=================================="
echo "下一步："
echo "1. 进入目录: cd $INSTALL_DIR"
echo "2. 运行初始化: ./init.sh"
echo ""
echo "或者直接运行:"
echo -e "${YELLOW}  cd $INSTALL_DIR && ./init.sh${NC}"

