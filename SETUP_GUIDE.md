# Barel Setup Guide

This guide ensures authentication works properly on fresh installations.

## Critical Files for Authentication

### 1. Environment Configuration
- **`.env.example`**: Must have `ENABLE_EMAIL_AUTOCONFIRM=true` for development
- **Keys**: Run `./scripts/generate-keys.sh` to generate matching JWT secret and API keys

### 2. Database Initialization
- **`volumes/db/init/00-initial-setup.sql`**: Creates users, schemas, and permissions
- **`volumes/db/init/01-fix-auth-migration.sql`**: Prevents auth migration failure

### 3. Kong API Gateway
- **`volumes/api/kong.yml.template`**: Template using environment variables
- **`volumes/api/kong.yml`**: Generated from template with actual keys

### 4. Quick Start Script
- **`quick-start.sh`**: 
  - Removes pgsodium from PostgreSQL config
  - Generates kong.yml from template
  - Sets up environment correctly

### 5. Project Initialization
- **`scripts/init-project.sh`**: 
  - Creates Next.js 15 compatible login page
  - Checks services are running before proceeding
  - Sources environment variables properly

## Common Issues and Solutions

### Auth Service Won't Start
**Error**: "operator does not exist: uuid = text"
**Solution**: The `01-fix-auth-migration.sql` file marks the problematic migration as completed

### Kong Returns 401 Unauthorized
**Cause**: Kong.yml has hardcoded demo keys that don't match JWT secret
**Solution**: Quick-start.sh generates kong.yml from template with correct keys

### Next.js searchParams Error
**Cause**: Next.js 15 requires awaiting searchParams
**Solution**: Login page template uses `async` function and `await searchParams`

### Email Confirmation Required
**Cause**: `ENABLE_EMAIL_AUTOCONFIRM=false` in production config
**Solution**: Set to `true` for development in .env.example

## Fresh Install Checklist

1. Clone repository
2. Run `./quick-start.sh`
3. Open in VS Code/Cursor
4. Reopen in Container
5. Inside container: `./scripts/init-project.sh`
6. Navigate to app directory: `cd app`
7. Start development: `npm run dev`

## Verification

Test authentication with:
```bash
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpassword123"}'
```

Check user creation:
```bash
docker compose exec db psql -U supabase_admin -d postgres -c "SELECT * FROM auth.users;"
```

## Services Health Check

All these services must be running:
- `devcontainer-db-1` (PostgreSQL)
- `devcontainer-kong-1` (API Gateway)
- `devcontainer-auth-1` (Authentication)
- `devcontainer-rest-1` (PostgREST)
- `devcontainer-studio-1` (Supabase Studio)

Check with: `docker compose ps`