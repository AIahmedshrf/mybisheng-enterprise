-- ========================================
-- Bisheng Enterprise - Database Initialization
-- ========================================
-- This script runs once when PostgreSQL starts for the first time
-- ========================================

-- ==================== Create Extensions ====================
\c bisheng_dev

-- UUID support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Full-text search for Arabic and Chinese
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- Performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- JSON functions
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Trigram similarity (for fuzzy search)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ==================== Create Schemas ====================
CREATE SCHEMA IF NOT EXISTS bisheng;
CREATE SCHEMA IF NOT EXISTS monitoring;
CREATE SCHEMA IF NOT EXISTS audit;

-- ==================== Set Search Path ====================
ALTER DATABASE bisheng_dev SET search_path TO bisheng, public;

-- ==================== Create Custom Types ====================

-- User roles
DO $$ BEGIN
    CREATE TYPE bisheng.user_role AS ENUM ('admin', 'user', 'guest', 'api');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Document status
DO $$ BEGIN
    CREATE TYPE bisheng.document_status AS ENUM ('pending', 'processing', 'completed', 'failed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==================== Create Tables ====================

-- Users table
CREATE TABLE IF NOT EXISTS bisheng.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role bisheng.user_role DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for users
CREATE INDEX IF NOT EXISTS idx_users_username ON bisheng.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON bisheng.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON bisheng.users(role);
CREATE INDEX IF NOT EXISTS idx_users_metadata ON bisheng.users USING gin(metadata);

-- Documents table
CREATE TABLE IF NOT EXISTS bisheng.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES bisheng.users(id) ON DELETE CASCADE,
    filename VARCHAR(500) NOT NULL,
    original_filename VARCHAR(500) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    status bisheng.document_status DEFAULT 'pending',
    content TEXT,
    embedding_id VARCHAR(255),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for documents
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON bisheng.documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON bisheng.documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON bisheng.documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_metadata ON bisheng.documents USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_documents_content_fts ON bisheng.documents USING gin(to_tsvector('english', content));

-- Conversations table
CREATE TABLE IF NOT EXISTS bisheng.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES bisheng.users(id) ON DELETE CASCADE,
    title VARCHAR(500),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON bisheng.conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON bisheng.conversations(created_at DESC);

-- Messages table
CREATE TABLE IF NOT EXISTS bisheng.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES bisheng.conversations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    tokens INTEGER,
    model VARCHAR(100),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON bisheng.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON bisheng.messages(created_at DESC);

-- API Keys table
CREATE TABLE IF NOT EXISTS bisheng.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES bisheng.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    key_prefix VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON bisheng.api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON bisheng.api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_is_active ON bisheng.api_keys(is_active);

-- Audit log table
CREATE TABLE IF NOT EXISTS audit.activity_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES bisheng.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON audit.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_action ON audit.activity_log(action);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON audit.activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_metadata ON audit.activity_log USING gin(metadata);

-- Monitoring table
CREATE TABLE IF NOT EXISTS monitoring.metrics (
    id BIGSERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC,
    tags JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_metrics_name ON monitoring.metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_created_at ON monitoring.metrics(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_tags ON monitoring.metrics USING gin(tags);

-- ==================== Create Functions ====================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION bisheng.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==================== Create Triggers ====================

-- Trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON bisheng.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON bisheng.users
    FOR EACH ROW
    EXECUTE FUNCTION bisheng.update_updated_at_column();

-- Trigger for documents table
DROP TRIGGER IF EXISTS update_documents_updated_at ON bisheng.documents;
CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON bisheng.documents
    FOR EACH ROW
    EXECUTE FUNCTION bisheng.update_updated_at_column();

-- Trigger for conversations table
DROP TRIGGER IF EXISTS update_conversations_updated_at ON bisheng.conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON bisheng.conversations
    FOR EACH ROW
    EXECUTE FUNCTION bisheng.update_updated_at_column();

-- ==================== Create Default Admin User ====================
-- Password: admin123 (CHANGE THIS IN PRODUCTION!)
INSERT INTO bisheng.users (username, email, password_hash, role)
VALUES (
    'admin',
    'admin@bisheng.local',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5FS9K6BrVfxJe',  -- hashed "admin123"
    'admin'
) ON CONFLICT (username) DO NOTHING;

-- ==================== Create Views ====================

-- View for active users
CREATE OR REPLACE VIEW bisheng.active_users AS
SELECT id, username, email, role, created_at, last_login
FROM bisheng.users
WHERE is_active = true;

-- View for document statistics
CREATE OR REPLACE VIEW bisheng.document_stats AS
SELECT 
    user_id,
    COUNT(*) as total_documents,
    SUM(file_size) as total_size,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_count
FROM bisheng.documents
GROUP BY user_id;

-- ==================== Permissions ====================

-- Grant permissions to bisheng user
GRANT ALL PRIVILEGES ON SCHEMA bisheng TO bisheng;
GRANT ALL PRIVILEGES ON SCHEMA monitoring TO bisheng;
GRANT ALL PRIVILEGES ON SCHEMA audit TO bisheng;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA bisheng TO bisheng;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA monitoring TO bisheng;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO bisheng;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA bisheng TO bisheng;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA monitoring TO bisheng;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO bisheng;

-- ==================== Vacuum and Analyze ====================
VACUUM ANALYZE;

-- ==================== Success Message ====================
\echo '========================================='
\echo 'Bisheng Database Initialization Complete!'
\echo '========================================='
\echo 'Schemas created: bisheng, monitoring, audit'
\echo 'Default admin user created: admin / admin123'
\echo 'Extensions installed: uuid-ossp, pg_trgm, pg_stat_statements'
\echo '========================================='

-- EOF
