#!/bin/bash

# Initialize a separate git repository for the app directory
# This supports the "App-Only Repository" workflow

set -euo pipefail

# Source the ASCII art functions
source "$(dirname "$0")/ascii-art.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Clear the screen and show the logo
clear
show_barel_logo

echo -e "${GREEN}App Repository Initialization${NC}"
echo "================================"
echo

# Check if we're in the Barel root directory
# Look in current directory or /workspace (when inside container)
if [ ! -f "barel.json" ] && [ ! -f "/workspace/barel.json" ]; then
    error_exit "This script must be run from the Barel root directory"
fi

# If we're inside the container, adjust paths
if [ -f "/workspace/barel.json" ] && [ ! -f "barel.json" ]; then
    cd /workspace
fi

# Check if app directory exists
if [ ! -d "app" ]; then
    error_exit "No app directory found. Please run ./scripts/init-project.sh first"
fi

# Change to app directory
cd app

# Check if already a git repository
if [ -d ".git" ]; then
    print_color "$YELLOW" "⚠️  The app directory is already a git repository"
    echo
    read -p "Do you want to reinitialize it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Cancelled"
        exit 0
    fi
    rm -rf .git
fi

# Initialize git repository
print_color "$GREEN" "Initializing git repository..."
git init

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_color "$GREEN" "Creating .gitignore..."
    if [ -f ".gitignore.template" ]; then
        cp .gitignore.template .gitignore
    else
        cat > .gitignore << 'EOF'
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# Supabase
supabase/.branches
supabase/.temp
EOF
    fi
fi

# Create initial commit
print_color "$GREEN" "Creating initial commit..."
git add .
git commit -m "Initial commit" || true

# Update parent repository's .gitignore
cd ..
if ! grep -q "^app/$" .gitignore 2>/dev/null; then
    print_color "$YELLOW" "\n📝 Note: To exclude the app directory from the Barel repository,"
    print_color "$YELLOW" "   uncomment the app/ section in the root .gitignore file"
fi

# Show success message
echo
show_success
echo
print_color "$GREEN" "✅ App repository initialized successfully!"
echo

# Show next steps
echo "Next steps:"
echo "1. Add your remote repository:"
echo "   ${GREEN}cd app${NC}"
echo "   ${GREEN}git remote add origin https://github.com/yourusername/your-app.git${NC}"
echo "   ${GREEN}git push -u origin main${NC}"
echo
echo "2. (Optional) Update the root .gitignore to exclude the app directory"
echo "   See the commented section at the bottom of .gitignore"
echo
echo "For more information, see ${GREEN}WORKFLOW_GUIDE.md${NC}"