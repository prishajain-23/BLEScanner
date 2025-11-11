#!/bin/bash

# Signal Protocol Deployment Script
# Target: 142.93.184.210

set -e

echo "🚀 Deploying Signal Protocol to Production"
echo "=========================================="
echo ""

# Check if deployment package exists
if [ ! -f "signal-protocol-deploy.tar.gz" ]; then
  echo "✗ Deployment package not found. Run: tar -czf signal-protocol-deploy.tar.gz ..."
  exit 1
fi

echo "✓ Deployment package found"
echo ""

# Step 1: Copy deployment package
echo "📦 Step 1: Copying deployment package to server..."
scp signal-protocol-deploy.tar.gz root@142.93.184.210:/tmp/
echo "✓ Package copied"
echo ""

# Step 2: SSH and deploy
echo "🔧 Step 2: Deploying on server..."
ssh root@142.93.184.210 << 'ENDSSH'
set -e

echo "Creating backup..."
mkdir -p /var/backups
pg_dump -U blescanner_user blescanner > /var/backups/blescanner_backup_$(date +%Y%m%d_%H%M%S).sql
cd /var/www/blescanner-backend
tar -czf /var/backups/blescanner_code_backup_$(date +%Y%m%d_%H%M%S).tar.gz server/
echo "✓ Backup created"

echo "Extracting new code..."
cd /var/www/blescanner-backend/server
tar -xzf /tmp/signal-protocol-deploy.tar.gz
echo "✓ Code extracted"

echo "Running database migration..."
psql -U blescanner_user -d blescanner -f db/migrations/002_signal_protocol.sql > /tmp/migration.log 2>&1
echo "✓ Migration complete"

echo "Installing dependencies..."
npm install --production > /tmp/npm-install.log 2>&1
echo "✓ Dependencies installed"

echo "Restarting server..."
pm2 restart blescanner-backend
sleep 3
echo "✓ Server restarted"

echo "Checking server status..."
pm2 status | grep blescanner-backend
ENDSSH

echo ""
echo "=========================================="
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Check logs: ssh root@142.93.184.210 'pm2 logs blescanner-backend'"
echo "2. Run tests: cd server && ./test-production.sh"
echo "3. Verify: curl http://142.93.184.210/health"
echo ""
