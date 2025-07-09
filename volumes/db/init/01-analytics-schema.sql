-- Create analytics schema for Logflare
CREATE SCHEMA IF NOT EXISTS _analytics;

-- Grant permissions
GRANT ALL ON SCHEMA _analytics TO supabase_admin;

-- Switch to the analytics schema
SET search_path TO _analytics;

-- Create required tables for Logflare
CREATE TABLE IF NOT EXISTS system_metrics (
    id BIGSERIAL PRIMARY KEY,
    all_logs_logged BIGINT DEFAULT 0,
    node VARCHAR(255) NOT NULL UNIQUE,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create other required tables
CREATE TABLE IF NOT EXISTS sources (
    id BIGSERIAL PRIMARY KEY,
    token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rules (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    regex VARCHAR(255),
    sink VARCHAR(255),
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Reset search path
RESET search_path;