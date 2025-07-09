#!/bin/bash
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐳 Docker Diagnostic Check${NC}"
echo "=========================="
echo ""

# Check if Docker is installed
echo -n "Docker installed: "
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Unknown")
    echo "  Version: $DOCKER_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo ""
    echo -e "${YELLOW}Docker is not installed. Please install Docker Desktop from:${NC}"
    echo "  https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# Check if Docker daemon is running
echo -n "Docker daemon running: "
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo ""
    echo -e "${YELLOW}Docker daemon is not running. Please start Docker Desktop.${NC}"
    echo ""
    echo "Common solutions:"
    echo "1. macOS: Open Docker Desktop from Applications"
    echo "2. Windows: Start Docker Desktop from Start Menu"
    echo "3. Linux: Run 'sudo systemctl start docker'"
    echo ""
    echo "If Docker Desktop is already open, try:"
    echo "- Quit and restart Docker Desktop"
    echo "- Check Docker Desktop settings"
    echo "- Ensure you have permissions to access Docker"
    exit 1
fi

# Check Docker Compose
echo -n "Docker Compose: "
if docker compose version >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "Unknown")
    echo "  Version: $COMPOSE_VERSION"
elif docker-compose --version >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} (legacy docker-compose found)"
    echo "  Consider upgrading to Docker Compose V2"
else
    echo -e "${RED}✗${NC}"
fi

# Check available resources
echo ""
echo "Docker Resources:"
DOCKER_INFO=$(docker info 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  CPUs: $(echo "$DOCKER_INFO" | grep "CPUs:" | awk '{print $2}')"
    echo "  Memory: $(echo "$DOCKER_INFO" | grep "Total Memory:" | awk '{print $3, $4}')"
    
    # Check if memory is sufficient
    MEMORY_GB=$(echo "$DOCKER_INFO" | grep "Total Memory:" | awk '{print $3}' | cut -d'.' -f1)
    if [ "$MEMORY_GB" -lt 8 ] 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}⚠️  Warning: Less than 8GB RAM allocated to Docker${NC}"
        echo "  Recommended: Increase Docker Desktop memory allocation"
    fi
fi

echo ""
echo -e "${GREEN}✅ Docker is ready for Barel!${NC}"