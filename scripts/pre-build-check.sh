#!/bin/bash
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Pre-build Environment Check${NC}"
echo "=============================="
echo ""

MISSING_VARS=()

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo ""
    echo "Please run: cp .env.example .env"
    echo "Then update the values in .env"
    exit 1
fi

# Source the .env file
set -a
source .env
set +a

# Check required environment variables
REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "JWT_SECRET"
    "ANON_KEY"
    "SERVICE_ROLE_KEY"
    "LOGFLARE_API_KEY"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please update your .env file with these values."
    echo "Run: ./scripts/generate-keys.sh to generate JWT keys"
    exit 1
fi

echo -e "${GREEN}✅ All environment variables set${NC}"

# Check if volumes directories exist
echo -n "Checking volume directories... "
if [ ! -d "volumes" ]; then
    echo -e "${YELLOW}Creating volumes directory${NC}"
    mkdir -p volumes/{db/init,api,logs,functions}
else
    echo -e "${GREEN}✓${NC}"
fi

# Check Docker
echo -n "Checking Docker... "
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}✗${NC}"
    echo ""
    echo -e "${RED}Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
else
    echo -e "${GREEN}✓${NC}"
fi

echo ""
echo -e "${GREEN}✅ Ready to build!${NC}"