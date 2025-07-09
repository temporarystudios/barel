-- Ensure auth user has proper permissions
-- This helps prevent permission issues during auth service startup

-- Grant all necessary permissions
GRANT ALL ON SCHEMA public TO supabase_auth_admin;
GRANT ALL ON SCHEMA extensions TO supabase_auth_admin;

-- Ensure the auth admin can use extensions
GRANT USAGE ON SCHEMA extensions TO supabase_auth_admin;