#!/bin/bash
# Apply database schema for an existing app

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to print error and exit
error_exit() {
    print_color "$RED" "❌ Error: $1"
    exit 1
}

# Source environment variables
if [ -f "/workspace/.env" ]; then
    set -a
    source /workspace/.env
    set +a
elif [ -f ".env" ]; then
    set -a
    source .env
    set +a
else
    error_exit ".env file not found!"
fi

# Check if schema file is provided or look for default
if [ -n "${1:-}" ]; then
    SCHEMA_FILE="$1"
else
    # Look for schema in common locations
    if [ -f "/workspace/app/supabase/schema.sql" ]; then
        SCHEMA_FILE="/workspace/app/supabase/schema.sql"
    elif [ -f "app/supabase/schema.sql" ]; then
        SCHEMA_FILE="app/supabase/schema.sql"
    elif [ -f "supabase/schema.sql" ]; then
        SCHEMA_FILE="supabase/schema.sql"
    else
        error_exit "No schema.sql file found. Please specify the path as an argument."
    fi
fi

# Check if schema file exists
if [ ! -f "$SCHEMA_FILE" ]; then
    error_exit "Schema file not found: $SCHEMA_FILE"
fi

print_color "$BLUE" "📊 Applying database schema from: $SCHEMA_FILE"

# Determine database host based on environment
if [ -f /.dockerenv ]; then
    # We're inside a container, use the service name
    DB_HOST="db"
else
    # We're on the host, use localhost
    DB_HOST="localhost"
fi

# Apply the schema
if PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p 5432 -U postgres -d postgres < "$SCHEMA_FILE"; then
    print_color "$GREEN" "✅ Database schema applied successfully!"
    echo ""
    print_color "$GREEN" "You should now be able to:"
    print_color "$GREEN" "  - Sign up and log in to your app"
    print_color "$GREEN" "  - View users in Supabase Studio at http://localhost:54321"
else
    error_exit "Failed to apply database schema. Check the error messages above."
fi