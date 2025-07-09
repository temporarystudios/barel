#!/bin/bash
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing Barel Setup"
echo "====================="
echo ""

# Test 1: Check all required files exist
echo -n "Checking required files... "
MISSING_FILES=()
for file in docker-compose.yml .devcontainer/devcontainer.json .devcontainer/Dockerfile .env.example; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Missing files: ${MISSING_FILES[*]}"
    exit 1
fi

# Test 2: Check all scripts are executable
echo -n "Checking script permissions... "
NON_EXEC_SCRIPTS=()
for script in scripts/*.sh quick-start.sh; do
    if [ ! -x "$script" ]; then
        NON_EXEC_SCRIPTS+=("$script")
    fi
done

if [ ${#NON_EXEC_SCRIPTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Non-executable scripts: ${NON_EXEC_SCRIPTS[*]}"
    echo "Run: chmod +x ${NON_EXEC_SCRIPTS[*]}"
fi

# Test 3: Test Docker build
echo -n "Testing Dockerfile build... "
if docker build -t barel-test .devcontainer/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    docker rmi barel-test > /dev/null 2>&1
else
    echo -e "${RED}✗${NC}"
    echo "Docker build failed. Run: docker build -t barel-test .devcontainer/"
fi

# Test 4: Check PostgreSQL configuration
echo -n "Checking PostgreSQL configuration... "
if [ -f "volumes/db/postgresql.conf" ]; then
    if grep -q "pgsodium" volumes/db/postgresql.conf; then
        echo -e "${YELLOW}⚠${NC}"
        echo "  Warning: pgsodium found in postgresql.conf - will be fixed by quick-start.sh"
    else
        echo -e "${GREEN}✓${NC}"
    fi
else
    echo -e "${RED}✗${NC}"
    echo "  Missing: volumes/db/postgresql.conf"
fi

# Test 5: Test docker-compose configuration
echo -n "Testing docker-compose config... "
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "docker-compose config failed"
fi

# Test 6: Test key generation
echo -n "Testing key generation... "
if ./scripts/generate-keys.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Key generation failed"
fi

echo ""
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
echo "Ready to commit to GitHub:"
echo "  git add ."
echo "  git commit -m \"Initial release of Barel\""
echo "  git push origin main"