#!/bin/bash
# Container initialization script that handles both firewall and npm install

echo "=== Container Initialization ==="

# Check if we're in a workspace with package.json
if [ -f "/workspace/package.json" ]; then
    echo "Found package.json, running npm install..."
    cd /workspace && npm install
else
    echo "No package.json found in /workspace, skipping npm install"
    echo "Run './scripts/init-project.sh' to create a new Next.js project"
fi

# Firewall setup (optional - skip if it fails)
echo "Setting up firewall (optional)..."
if sudo /usr/local/bin/init-firewall-simple.sh 2>/dev/null; then
    echo "Firewall configured successfully"
else
    echo "Firewall setup skipped (this is okay for local development)"
fi

# Display helpful information
echo ""
echo "=== Container initialization complete ==="
echo ""

# Show welcome art if available
if [ -f "/workspace/scripts/ascii-art.sh" ]; then
    source /workspace/scripts/ascii-art.sh
    show_welcome
else
    echo "🚀 Welcome to Barel Development Container!"
fi
echo ""
echo "Available services:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Supabase API: http://localhost:8000"
echo "  - Supabase Studio: http://localhost:54321"
echo "  - Next.js App: http://localhost:3000 (after project setup)"
echo ""
echo "To create a new project, run: ./scripts/init-project.sh"
echo ""