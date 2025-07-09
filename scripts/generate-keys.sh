#!/bin/bash
set -euo pipefail

echo "🔐 Generating Supabase Keys"
echo "==========================="
echo ""

# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"
echo ""

# Create a temporary directory for our work
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Initialize a minimal package.json
cat > package.json << EOF
{
  "name": "temp-jwt-generator",
  "version": "1.0.0",
  "private": true
}
EOF

# Create the JWT generation script
cat > generate-jwt.js << EOF
const jwt = require('jsonwebtoken');

const jwtSecret = process.argv[2];

const anonToken = jwt.sign(
  {
    role: 'anon',
    iss: 'supabase',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (10 * 365 * 24 * 60 * 60), // 10 years
  },
  jwtSecret
);

const serviceToken = jwt.sign(
  {
    role: 'service_role',
    iss: 'supabase',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (10 * 365 * 24 * 60 * 60), // 10 years
  },
  jwtSecret
);

console.log('ANON_KEY=' + anonToken);
console.log('SERVICE_ROLE_KEY=' + serviceToken);
EOF

# Install jsonwebtoken in the temp directory
echo "Installing dependencies..."
npm install jsonwebtoken --silent 2>/dev/null || {
    echo "❌ Failed to install jsonwebtoken. Please ensure npm is installed."
    rm -rf "$TEMP_DIR"
    exit 1
}

# Generate the keys
node generate-jwt.js "$JWT_SECRET"

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Keys generated successfully!"
echo ""

# Check if we should update .env file
if [ "${1:-}" == "--update-env" ] && [ -f "../.env" ]; then
    echo "Updating .env file..."
    
    # Extract the generated values
    JWT_VALUE=$(echo "$JWT_SECRET" | head -1)
    ANON_VALUE=$(node generate-jwt.js "$JWT_SECRET" | grep "ANON_KEY=" | cut -d'=' -f2)
    SERVICE_VALUE=$(node generate-jwt.js "$JWT_SECRET" | grep "SERVICE_ROLE_KEY=" | cut -d'=' -f2)
    
    # Update .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=$JWT_VALUE|" ../.env
        sed -i '' "s|ANON_KEY=.*|ANON_KEY=$ANON_VALUE|" ../.env
        sed -i '' "s|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_VALUE|" ../.env
    else
        # Linux
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_VALUE|" ../.env
        sed -i "s|ANON_KEY=.*|ANON_KEY=$ANON_VALUE|" ../.env
        sed -i "s|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_VALUE|" ../.env
    fi
    
    echo "✅ .env file updated with new keys!"
else
    echo "Copy these values to your .env file:"
    echo "- JWT_SECRET"
    echo "- ANON_KEY"
    echo "- SERVICE_ROLE_KEY"
fi

echo ""
echo "⚠️  Keep these keys secure and never commit them to version control!"