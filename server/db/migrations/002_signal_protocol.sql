-- Signal Protocol E2EE Migration
-- Creates tables for identity keys, prekeys, and modifies messages table

-- 1. Identity Keys Table
-- Stores public identity keys for each user (long-term)
CREATE TABLE identity_keys (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    public_key BYTEA NOT NULL,  -- 32 bytes (Curve25519 public key)
    registration_id INTEGER NOT NULL,  -- Signal Protocol registration ID
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_identity_keys_user ON identity_keys(user_id);

-- 2. Signed Prekeys Table
-- Stores signed prekeys (medium-term, rotated periodically)
CREATE TABLE signed_prekeys (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key_id INTEGER NOT NULL,  -- Unique ID for this prekey
    public_key BYTEA NOT NULL,  -- 32 bytes
    signature BYTEA NOT NULL,  -- Signature of public_key by identity key
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, key_id)
);

CREATE INDEX idx_signed_prekeys_user ON signed_prekeys(user_id);

-- 3. One-Time Prekeys Table
-- Stores one-time prekeys (single-use, batch uploaded)
CREATE TABLE one_time_prekeys (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key_id INTEGER NOT NULL,  -- Unique ID for this prekey
    public_key BYTEA NOT NULL,  -- 32 bytes
    consumed BOOLEAN DEFAULT FALSE,  -- Marked true when used
    consumed_at TIMESTAMP,
    consumed_by INTEGER REFERENCES users(id),  -- Who consumed it
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, key_id)
);

-- Optimized index for fetching available prekeys
CREATE INDEX idx_one_time_prekeys_user_available ON one_time_prekeys(user_id, consumed) WHERE consumed = FALSE;
CREATE INDEX idx_one_time_prekeys_key_id ON one_time_prekeys(key_id);

-- 4. Backup Old Messages Table (before migration)
-- Preserves plaintext messages for reference (can be dropped after verification)
CREATE TABLE messages_backup AS SELECT * FROM messages;

-- 5. Modify Messages Table
-- Add new columns for encrypted messages
ALTER TABLE messages
    ADD COLUMN encrypted_payload BYTEA,  -- Encrypted message content
    ADD COLUMN sender_ratchet_key BYTEA,  -- Sender's current ratchet public key
    ADD COLUMN counter INTEGER,  -- Message counter in chain
    ADD COLUMN encryption_version INTEGER DEFAULT 1;  -- 0=plaintext, 1=Signal Protocol

-- Make message_text nullable (encrypted messages won't have plaintext)
ALTER TABLE messages ALTER COLUMN message_text DROP NOT NULL;

-- Note: message_text column will be deprecated but kept for backwards compatibility
-- After migration, all new messages will use encrypted_payload instead

-- 6. Add Prekey Count to Users Table
-- Track available one-time prekeys for monitoring
ALTER TABLE users
    ADD COLUMN prekey_count INTEGER DEFAULT 0;

-- Comments for documentation
COMMENT ON TABLE identity_keys IS 'Stores user public identity keys for Signal Protocol';
COMMENT ON TABLE signed_prekeys IS 'Stores signed prekeys, rotated periodically for forward secrecy';
COMMENT ON TABLE one_time_prekeys IS 'Stores single-use prekeys for session establishment';
COMMENT ON COLUMN messages.encrypted_payload IS 'Signal Protocol encrypted message content';
COMMENT ON COLUMN messages.encryption_version IS '0=plaintext (legacy), 1=Signal Protocol encrypted';

-- Migration complete
-- Next steps:
-- 1. Run this migration on development database
-- 2. Test key upload/retrieval endpoints
-- 3. After verification, delete old plaintext messages:
--    DELETE FROM messages WHERE encryption_version = 0 OR encryption_version IS NULL;
-- 4. Remove message_text column:
--    ALTER TABLE messages DROP COLUMN message_text;
