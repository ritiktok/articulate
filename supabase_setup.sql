-- =====================================================
-- ARTICULATE CANVAS APP DATABASE SETUP
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- CANVAS SESSIONS TABLE
-- =====================================================

-- Add columns for existing deployments
ALTER TABLE canvas_sessions ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE canvas_sessions ADD COLUMN IF NOT EXISTS created_by TEXT;

-- Remove old columns for existing deployments
ALTER TABLE canvas_sessions DROP COLUMN IF EXISTS participants;
ALTER TABLE canvas_sessions DROP COLUMN IF EXISTS last_activity;
ALTER TABLE canvas_sessions DROP COLUMN IF EXISTS is_active;

-- Updated CREATE TABLE for new deployments
CREATE TABLE IF NOT EXISTS canvas_sessions (
    id TEXT PRIMARY KEY,
    title TEXT,
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for canvas_sessions
CREATE INDEX IF NOT EXISTS idx_canvas_sessions_created_at 
ON canvas_sessions(created_at DESC);

-- =====================================================
-- DRAWING STROKES TABLE
-- =====================================================

-- Add columns for existing deployments
ALTER TABLE drawing_strokes ADD COLUMN IF NOT EXISTS operation TEXT DEFAULT 'draw';
ALTER TABLE drawing_strokes ADD COLUMN IF NOT EXISTS target_stroke_id TEXT;
ALTER TABLE drawing_strokes ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE drawing_strokes ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Remove old columns for existing deployments
ALTER TABLE drawing_strokes DROP COLUMN IF EXISTS updated_at;
ALTER TABLE drawing_strokes DROP COLUMN IF EXISTS is_deleted;
ALTER TABLE drawing_strokes DROP COLUMN IF EXISTS pending_sync;

-- Updated CREATE TABLE for new deployments
CREATE TABLE IF NOT EXISTS drawing_strokes (
    id UUID PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES canvas_sessions(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    points TEXT NOT NULL, -- JSON array of drawing points
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    operation TEXT NOT NULL DEFAULT 'draw', -- 'draw', 'undo', 'redo', 'clear'
    target_stroke_id TEXT, -- UUID of target stroke for undo/redo operations
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- Whether this stroke is currently active
    version INTEGER -- Version for conflict resolution (nullable for offline strokes)
);

-- Indexes for drawing_strokes
CREATE INDEX IF NOT EXISTS idx_drawing_strokes_session_id 
ON drawing_strokes(session_id);

CREATE INDEX IF NOT EXISTS idx_drawing_strokes_user_id 
ON drawing_strokes(user_id);

CREATE INDEX IF NOT EXISTS idx_drawing_strokes_created_at 
ON drawing_strokes(created_at);



-- =====================================================
-- CONFLICTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    local_stroke_id UUID,
    remote_stroke_id UUID,
    reason TEXT NOT NULL, -- e.g. 'version_conflict'
    resolved_by UUID, -- user or system
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- Indexes for conflicts table
CREATE INDEX IF NOT EXISTS idx_conflicts_local_stroke_id 
ON conflicts(local_stroke_id);

CREATE INDEX IF NOT EXISTS idx_conflicts_remote_stroke_id 
ON conflicts(remote_stroke_id);

CREATE INDEX IF NOT EXISTS idx_conflicts_timestamp 
ON conflicts(timestamp DESC);

-- =====================================================
-- REAL-TIME SETUP
-- =====================================================

-- Set replica identity for real-time subscriptions
ALTER TABLE canvas_sessions REPLICA IDENTITY FULL;
ALTER TABLE drawing_strokes REPLICA IDENTITY FULL;
ALTER TABLE conflicts REPLICA IDENTITY FULL;

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to get the next version number for a session
CREATE OR REPLACE FUNCTION get_next_version(p_session_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    max_version INTEGER;
BEGIN
    SELECT COALESCE(MAX(version), 0) INTO max_version
    FROM drawing_strokes
    WHERE session_id = p_session_id;
    
    RETURN max_version + 1;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-increment version for new strokes
CREATE OR REPLACE FUNCTION update_version_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.version IS NULL THEN
        NEW.version = get_next_version(NEW.session_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for version auto-increment
DROP TRIGGER IF EXISTS trigger_update_version ON drawing_strokes;
CREATE TRIGGER trigger_update_version
    BEFORE INSERT ON drawing_strokes
    FOR EACH ROW
    EXECUTE FUNCTION update_version_on_insert();

 
 -- =====================================================
-- POSTGRESQL FUNCTIONS FOR COLLABORATIVE UNDO/REDO/CLEAR
-- =====================================================

-- Function to handle UNDO operation
CREATE OR REPLACE FUNCTION handle_undo_operation()
RETURNS TRIGGER AS $$
DECLARE
    found_stroke_id TEXT;
    found_version INTEGER;
BEGIN
    -- Only process if this is an undo operation
    IF NEW.operation = 'undo' THEN
        -- Find the last active draw stroke in this session
        SELECT id, version INTO found_stroke_id, found_version
        FROM drawing_strokes
        WHERE session_id = NEW.session_id
          AND operation = 'draw'
          AND is_active = true
        ORDER BY version DESC
        LIMIT 1;
        
        -- If we found a target stroke, update it
        IF found_stroke_id IS NOT NULL THEN
            -- Update the target stroke to inactive
            UPDATE drawing_strokes
            SET is_active = false
            WHERE id = found_stroke_id
              AND session_id = NEW.session_id;
            
            -- Set the target_stroke_id in the undo operation
            NEW.target_stroke_id := found_stroke_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle REDO operation
CREATE OR REPLACE FUNCTION handle_redo_operation()
RETURNS TRIGGER AS $$
DECLARE
    last_undo_stroke_id TEXT;
    found_target_stroke_id TEXT;
BEGIN
    -- Only process if this is a redo operation
    IF NEW.operation = 'redo' THEN
        -- Find the most recent undo stroke that can be redone
        SELECT id, target_stroke_id INTO last_undo_stroke_id, found_target_stroke_id
        FROM drawing_strokes
        WHERE session_id = NEW.session_id
          AND operation = 'undo'
          AND target_stroke_id IS NOT NULL
        ORDER BY version DESC
        LIMIT 1;
        
        -- If we found a valid undo operation
        IF last_undo_stroke_id IS NOT NULL AND found_target_stroke_id IS NOT NULL THEN
            -- Check if the target stroke is currently inactive
            IF EXISTS (
                SELECT 1 FROM drawing_strokes
                WHERE id = found_target_stroke_id
                  AND session_id = NEW.session_id
                  AND is_active = false
            ) THEN
                -- Update the target stroke to active
                UPDATE drawing_strokes
                SET is_active = true
                WHERE id = found_target_stroke_id
                  AND session_id = NEW.session_id;
                
                -- Set the target_stroke_id in the redo operation
                NEW.target_stroke_id := found_target_stroke_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle CLEAR operation
CREATE OR REPLACE FUNCTION handle_clear_operation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if this is a clear operation
    IF NEW.operation = 'clear' THEN
        -- Deactivate all draw strokes in the session
        UPDATE drawing_strokes
        SET is_active = false
        WHERE session_id = NEW.session_id
          AND operation = 'draw';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- =====================================================
-- TRIGGERS
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_handle_undo ON drawing_strokes;
DROP TRIGGER IF EXISTS trigger_handle_redo ON drawing_strokes;
DROP TRIGGER IF EXISTS trigger_handle_clear ON drawing_strokes;

-- Create trigger for undo operations
CREATE TRIGGER trigger_handle_undo
    BEFORE INSERT ON drawing_strokes
    FOR EACH ROW
    EXECUTE FUNCTION handle_undo_operation();

-- Create trigger for redo operations
CREATE TRIGGER trigger_handle_redo
    BEFORE INSERT ON drawing_strokes
    FOR EACH ROW
    EXECUTE FUNCTION handle_redo_operation();

-- Create trigger for clear operations
CREATE TRIGGER trigger_handle_clear
    BEFORE INSERT ON drawing_strokes
    FOR EACH ROW
    EXECUTE FUNCTION handle_clear_operation();

-- =====================================================
-- VIEW FOR ACTIVE STROKES ONLY
-- =====================================================

-- Create a view that only shows active draw strokes
CREATE OR REPLACE VIEW active_strokes AS
SELECT *
FROM drawing_strokes
WHERE operation = 'draw'
  AND is_active = true
ORDER BY version ASC;

 