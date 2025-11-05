#!/bin/bash

# BLEScanner PostgreSQL Database Setup Script

set -e

echo "======================================"
echo "PostgreSQL Database Setup"
echo "======================================"

# Generate a random password for the database user
DB_PASSWORD=$(openssl rand -base64 32)

echo ""
echo "Creating database and user..."

# Run SQL commands as postgres user
sudo -u postgres psql << EOF
-- Create database
CREATE DATABASE blescanner;

-- Create user with generated password
CREATE USER blescanner_user WITH PASSWORD '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE blescanner TO blescanner_user;

-- Connect to blescanner database
\c blescanner

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO blescanner_user;

-- Grant table privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO blescanner_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO blescanner_user;

EOF

echo ""
echo "✓ Database created successfully!"
echo ""
echo "======================================"
echo "Database Credentials:"
echo "======================================"
echo "DB_HOST=localhost"
echo "DB_PORT=5432"
echo "DB_NAME=blescanner"
echo "DB_USER=blescanner_user"
echo "DB_PASSWORD=$DB_PASSWORD"
echo ""
echo "IMPORTANT: Save these credentials!"
echo "You'll need them for the .env file"
echo "======================================"
