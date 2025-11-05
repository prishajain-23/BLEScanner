#!/bin/bash

# BLEScanner Backend Deployment Script

set -e

APP_DIR="/var/www/blescanner-backend"

echo "======================================"
echo "Deploying BLEScanner Backend"
echo "======================================"

# Navigate to app directory
cd $APP_DIR

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    echo ""
    echo "[1/6] Pulling latest changes..."
    git pull origin main
else
    echo ""
    echo "[1/6] Skipping git pull (not a git repository)"
fi

# Install dependencies
echo ""
echo "[2/6] Installing dependencies..."
cd server
npm install --production

# Run database migrations
echo ""
echo "[3/6] Running database migrations..."
if [ -f ".env" ]; then
    # Source the .env file to get database credentials
    export $(grep -v '^#' .env | xargs)

    # Run schema SQL
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f db/schema.sql 2>&1 | grep -v "already exists" || true

    echo "Database migrations complete"
else
    echo "WARNING: No .env file found. Skipping database migrations."
    echo "Please create .env file and run migrations manually."
fi

# Stop existing PM2 process
echo ""
echo "[4/6] Stopping existing process..."
pm2 stop blescanner-backend || true
pm2 delete blescanner-backend || true

# Start with PM2
echo ""
echo "[5/6] Starting application with PM2..."
pm2 start index.js --name blescanner-backend

# Save PM2 configuration
echo ""
echo "[6/6] Saving PM2 configuration..."
pm2 save

# Show status
echo ""
pm2 status

echo ""
echo "======================================"
echo "✓ Deployment complete!"
echo "======================================"
echo ""
echo "Application is running on port 3000"
echo "View logs with: pm2 logs blescanner-backend"
echo "Restart with: pm2 restart blescanner-backend"
echo ""
