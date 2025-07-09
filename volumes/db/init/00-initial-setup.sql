-- Create required users and databases for Supabase
-- This script runs on first database initialization

-- Ensure we're using the postgres database
\c postgres

-- Create the supabase_admin user if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'supabase_admin') THEN
        CREATE USER supabase_admin WITH SUPERUSER PASSWORD 'postgres-dev-password-change-me';
    END IF;
END
$$;

-- Create the authenticator user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'authenticator') THEN
        CREATE USER authenticator WITH LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD 'postgres-dev-password-change-me';
    END IF;
END
$$;

-- Create service role users
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'supabase_auth_admin') THEN
        CREATE USER supabase_auth_admin NOINHERIT CREATEROLE LOGIN PASSWORD 'postgres-dev-password-change-me';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'supabase_storage_admin') THEN
        CREATE USER supabase_storage_admin NOINHERIT CREATEROLE LOGIN PASSWORD 'postgres-dev-password-change-me';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'supabase_functions_admin') THEN
        CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN PASSWORD 'postgres-dev-password-change-me';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'supabase_realtime_admin') THEN
        CREATE USER supabase_realtime_admin NOINHERIT CREATEROLE LOGIN PASSWORD 'postgres-dev-password-change-me';
    END IF;
END
$$;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_admin;
GRANT ALL PRIVILEGES ON SCHEMA public TO supabase_admin;
GRANT ALL PRIVILEGES ON SCHEMA public TO supabase_auth_admin;
GRANT CREATE ON DATABASE postgres TO supabase_auth_admin;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Create required extensions in extensions schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgjwt" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA extensions;

-- Grant permissions on extensions
GRANT USAGE ON SCHEMA extensions TO supabase_auth_admin, supabase_storage_admin;

-- Set search path for auth admin to ensure it can find tables
ALTER USER supabase_auth_admin SET search_path = auth, public, extensions;

-- Create realtime schema
CREATE SCHEMA IF NOT EXISTS realtime AUTHORIZATION supabase_realtime_admin;

-- Create storage schema  
CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION supabase_storage_admin;

-- Grant permissions to authenticator
GRANT USAGE ON SCHEMA public, auth, storage TO authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public, auth, storage TO authenticator;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public, auth, storage TO authenticator;
GRANT ALL ON ALL ROUTINES IN SCHEMA public, auth, storage TO authenticator;

-- Note: pgsodium extension is intentionally omitted due to missing getkey script
-- It can be added later when properly configured