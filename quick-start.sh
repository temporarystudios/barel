#!/bin/bash
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source ASCII art functions
source ./scripts/ascii-art.sh

# Show logo
show_barel_logo
echo ""

# Check Docker first
echo "Checking Docker..."
if ! ./scripts/check-docker.sh > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker check failed!${NC}"
    echo "Please run: ./scripts/check-docker.sh"
    exit 1
fi
echo -e "${GREEN}✓ Docker is ready${NC}"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Setting up environment...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env file with development defaults${NC}"
    echo ""
    
    echo -e "${YELLOW}Would you like to generate secure keys for production? (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Generating secure keys...${NC}"
        
        # Generate keys and capture output
        TEMP_KEYS=$(mktemp)
        if ./scripts/generate-keys.sh > "$TEMP_KEYS" 2>&1; then
            # Extract the generated values
            JWT_SECRET=$(grep "^JWT_SECRET=" "$TEMP_KEYS" | cut -d'=' -f2)
            ANON_KEY=$(grep "^ANON_KEY=" "$TEMP_KEYS" | cut -d'=' -f2)
            SERVICE_ROLE_KEY=$(grep "^SERVICE_ROLE_KEY=" "$TEMP_KEYS" | cut -d'=' -f2)
            
            if [ -n "$JWT_SECRET" ] && [ -n "$ANON_KEY" ] && [ -n "$SERVICE_ROLE_KEY" ]; then
                # Update .env file
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
                    sed -i '' "s|ANON_KEY=.*|ANON_KEY=$ANON_KEY|" .env
                    sed -i '' "s|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
                else
                    # Linux
                    sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
                    sed -i "s|ANON_KEY=.*|ANON_KEY=$ANON_KEY|" .env
                    sed -i "s|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
                fi
                
                echo -e "${GREEN}✓ Keys generated and applied to .env file!${NC}"
                echo ""
                echo "Generated keys:"
                echo "JWT_SECRET=$JWT_SECRET"
                echo "ANON_KEY=$(echo $ANON_KEY | cut -c1-50)..."
                echo "SERVICE_ROLE_KEY=$(echo $SERVICE_ROLE_KEY | cut -c1-50)..."
            else
                echo -e "${RED}❌ Failed to extract keys. Using development keys instead.${NC}"
                cat "$TEMP_KEYS"
            fi
        else
            echo -e "${RED}❌ Failed to generate keys. Using development keys instead.${NC}"
            cat "$TEMP_KEYS"
        fi
        
        rm -f "$TEMP_KEYS"
    else
        echo -e "${GREEN}✓ Using development keys (perfect for local development!)${NC}"
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Ensure PostgreSQL config exists with proper settings
echo -e "${YELLOW}Checking PostgreSQL configuration...${NC}"
if [ ! -f "volumes/db/postgresql.conf" ]; then
    echo -e "${RED}❌ PostgreSQL configuration missing. Creating from backup...${NC}"
    if [ -f "volumes/db/postgresql.conf.backup" ]; then
        cp volumes/db/postgresql.conf.backup volumes/db/postgresql.conf
    else
        echo -e "${RED}❌ No backup found. Please check the repository.${NC}"
        exit 1
    fi
fi

# Ensure pgsodium is not in preloaded libraries (known issue)
if grep -q "pgsodium" volumes/db/postgresql.conf; then
    echo -e "${YELLOW}Fixing PostgreSQL configuration...${NC}"
    sed -i.bak "s/,pgsodium//g" volumes/db/postgresql.conf
    echo -e "${GREEN}✓ PostgreSQL configuration fixed${NC}"
fi

# Generate kong.yml from template with current keys
echo -e "${YELLOW}Configuring API Gateway...${NC}"
if [ -f "volumes/api/kong.yml.template" ]; then
    # Source the .env file to get the keys
    source .env
    # Replace placeholders in template
    sed "s/\${ANON_KEY}/$ANON_KEY/g; s/\${SERVICE_ROLE_KEY}/$SERVICE_ROLE_KEY/g" \
        volumes/api/kong.yml.template > volumes/api/kong.yml
    echo -e "${GREEN}✓ API Gateway configured${NC}"
else
    echo -e "${YELLOW}⚠️  Kong template not found, using existing configuration${NC}"
fi

echo -e "${CYAN}Opening in your editor...${NC}"
# Try Cursor first, then VS Code
if command -v cursor >/dev/null 2>&1; then
    cursor .
elif command -v code >/dev/null 2>&1; then
    code .
else
    echo -e "${YELLOW}⚠️  Please open this folder in VS Code or Cursor manually${NC}"
fi

echo ""
show_success
echo -e "${YELLOW}Next steps:${NC}"
echo "1. In your editor:"
echo "   - VS Code: Press F1 and select 'Dev Containers: Reopen in Container'"
echo "   - Cursor: Press Cmd/Ctrl+Shift+P and select 'Dev Containers: Reopen in Container'"
echo ""
echo "2. The Dev Container extension will automatically:"
echo "   - Build the Docker images"
echo "   - Start all Supabase services"
echo "   - Open a new window inside the container"
echo "   - This takes 5-10 minutes on first run"
echo ""
echo "3. Once inside the container (you'll see [Dev Container] in the window title):"
echo "   - Run: ./scripts/init-project.sh"
echo "   - Start coding!"
echo ""
echo -e "${CYAN}No manual Docker commands needed - the extension handles everything! 🎉${NC}"