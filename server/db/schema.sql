-- BLEScanner Messaging System Database Schema
-- Version: 1.0.0
-- Created: 2025-11-04

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS message_recipients CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS contacts CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    device_token VARCHAR(255),  -- APNs device token
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Messages table
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    from_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    device_name VARCHAR(100),  -- ESP32 device name (e.g., "Living Room Sensor")
    created_at TIMESTAMP DEFAULT NOW()
);

-- Message recipients (many-to-many relationship)
CREATE TABLE message_recipients (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
    to_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    delivered BOOLEAN DEFAULT FALSE,
    delivered_at TIMESTAMP,
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    UNIQUE(message_id, to_user_id)
);

-- Contacts (who can message whom)
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    nickname VARCHAR(100),  -- Optional friendly name
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, contact_user_id),
    CHECK(user_id != contact_user_id)  -- Can't add yourself
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_messages_from ON messages(from_user_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_recipients_user ON message_recipients(to_user_id);
CREATE INDEX idx_recipients_message ON message_recipients(message_id);
CREATE INDEX idx_contacts_user ON contacts(user_id);
CREATE INDEX idx_contacts_search ON contacts(contact_user_id);

-- Verify tables were created
SELECT 'Database schema created successfully!' AS status;
SELECT 'Tables created: users, messages, message_recipients, contacts' AS info;
