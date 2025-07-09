#!/bin/bash
set -euo pipefail

echo "Checking Supabase services health..."
echo "===================================="

# Check PostgreSQL
echo -n "PostgreSQL: "
if pg_isready -h db -p 5432 -U postgres > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check Kong API Gateway
echo -n "Kong API Gateway: "
if curl -s -o /dev/null -w "%{http_code}" http://kong:8000/health | grep -q "200"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check Supabase Studio
echo -n "Supabase Studio: "
if curl -s -o /dev/null -w "%{http_code}" http://studio:3000/api/profile | grep -q "200\|401"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check Auth Service
echo -n "Auth Service: "
if curl -s -o /dev/null -w "%{http_code}" http://auth:9999/health | grep -q "200"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check Realtime
echo -n "Realtime: "
if curl -s -o /dev/null -w "%{http_code}" http://realtime:4000/api/tenants/realtime-dev/health | grep -q "200"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check Storage
echo -n "Storage: "
if curl -s -o /dev/null -w "%{http_code}" http://storage:5000/status | grep -q "200"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

# Check PostgREST
echo -n "PostgREST: "
if curl -s -o /dev/null -w "%{http_code}" http://rest:3000 | grep -q "200"; then
    echo "✅ Healthy"
else
    echo "❌ Not responding"
fi

echo "===================================="
echo "Service URLs:"
echo "Supabase Studio: http://localhost:54321"
echo "API Gateway: http://localhost:8000"
echo "Database: postgresql://postgres:${POSTGRES_PASSWORD}@localhost:5432/postgres"