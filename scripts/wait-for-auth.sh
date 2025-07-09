#!/bin/bash
# Wait for auth service to be healthy before proceeding

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

MAX_RETRIES=30
RETRY_COUNT=0

# Determine auth service host based on environment
if [ -f /.dockerenv ]; then
    # We're inside a container, check via network
    AUTH_URL="http://auth:9999/health"
else
    # We're on the host, check via localhost
    AUTH_URL="http://localhost:9999/health"
fi

echo -e "${YELLOW}Waiting for auth service to be ready...${NC}"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Try to reach auth health endpoint
    if curl -s "$AUTH_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Auth service is ready${NC}"
        exit 0
    fi
    
    echo -n "."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 2
done

echo -e "${RED}❌ Auth service failed to become ready after $MAX_RETRIES attempts${NC}"
echo -e "${YELLOW}You can try applying the schema manually later with:${NC}"
echo -e "${YELLOW}./scripts/apply-schema.sh${NC}"
# Exit with error code to indicate failure
exit 1