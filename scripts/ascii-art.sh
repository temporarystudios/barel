#!/bin/bash

# Color codes
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Barel ASCII Art
show_barel_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ____                  _ 
   |  _ \                | |
   | |_) | __ _ _ __ ___| |
   |  _ < / _` | '__/ _ \ |
   | |_) | (_| | | |  __/ |
   |____/ \__,_|_|  \___|_|
                           
   Next.js + Supabase Dev Container
   ================================
EOF
    echo -e "${NC}"
}

# Alternative logo with barrel design
show_barel_barrel() {
    echo -e "${CYAN}"
    cat << 'EOF'
     _____________________
    /                     \
   |  ___    ___    ___   |
   | |   |  |   |  |   |  |
   | | B |  | a |  | r |  |
   | |___|  |___|  |___|  |
   |  ___    ___    ___   |
   | |   |  |   |  |   |  |
   | | e |  | l |  | ! |  |
   | |___|  |___|  |___|  |
   |                      |
    \____________________/
    
    Next.js + Supabase + AI
    =======================
EOF
    echo -e "${NC}"
}

# Success celebration
show_success() {
    echo -e "${GREEN}"
    cat << 'EOF'
    
    🎉 ✨ 🚀 SUCCESS! 🚀 ✨ 🎉
    ========================
    
    Your Barel container is ready!
    
EOF
    echo -e "${NC}"
}

# Welcome message
show_welcome() {
    echo -e "${BLUE}"
    cat << 'EOF'
    ╔═══════════════════════════════╗
    ║   Welcome to Barel Dev Env    ║
    ║   Your Full-Stack Workspace   ║
    ╚═══════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Export functions so they can be sourced
export -f show_barel_logo
export -f show_barel_barrel
export -f show_success
export -f show_welcome