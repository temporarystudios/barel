-- Fix for auth service startup
-- The auth service needs to create its own schema and tables
-- We just need to ensure it has the right permissions

-- Grant necessary permissions to auth admin user
GRANT CREATE ON DATABASE postgres TO supabase_auth_admin;