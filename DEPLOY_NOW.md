# Deploy Signal Protocol - Manual Steps

Since automated SSH deployment requires key setup, here are the exact commands to run in your terminal:

---

## Step 1: Copy Deployment Package

```bash
# Open Terminal and run:
cd /Users/prishajain/Desktop/GitHub/BLEScanner

# Copy deployment package to server
scp signal-protocol-deploy.tar.gz root@142.93.184.210:/tmp/
```

**Enter your SSH password when prompted.**

---

## Step 2: SSH to Server and Deploy

```bash
# SSH to server
ssh root@142.93.184.210
```

**Enter your SSH password when prompted.**

Once connected, run these commands:

```bash
# Create backups
mkdir -p /var/backups
echo "Creating database backup..."
pg_dump -U blescanner_user blescanner > /var/backups/blescanner_backup_$(date +%Y%m%d_%H%M%S).sql

echo "Creating code backup..."
cd /var/www/blescanner-backend
tar -czf /var/backups/blescanner_code_backup_$(date +%Y%m%d_%H%M%S).tar.gz server/

# Extract new code
echo "Extracting new code..."
cd /var/www/blescanner-backend/server
tar -xzf /tmp/signal-protocol-deploy.tar.gz

# Run database migration
echo "Running database migration..."
psql -U blescanner_user -d blescanner -f db/migrations/002_signal_protocol.sql

# Install dependencies
echo "Installing dependencies..."
npm install

# Restart server
echo "Restarting server..."
pm2 restart blescanner-backend

# Check status
pm2 status

# View logs (Ctrl+C to exit)
pm2 logs blescanner-backend --lines 30
```

**Look for these lines in the logs:**
```
✅ BLEScanner Backend API Server Running
POST /api/keys/upload - Upload Signal Protocol keys
GET  /api/keys/bundle/:userId - Get prekey bundle
```

**If you see these, deployment is successful!**

---

## Step 3: Verify Deployment

While still SSH'd to the server:

```bash
# Test health endpoint
curl http://localhost:3000/health

# Check database tables
psql -U blescanner_user -d blescanner -c "\dt" | grep -E "(identity_keys|signed_prekeys|one_time_prekeys)"

# Should see:
# public | identity_keys      | table | blescanner_user
# public | one_time_prekeys   | table | blescanner_user
# public | signed_prekeys     | table | blescanner_user

# Exit SSH
exit
```

---

## Step 4: Run Production Tests

Back on your local machine:

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Run production tests
./test-production.sh
```

**Expected output:** All 14 tests should pass!

---

## Quick Test from Browser

Open in your browser: http://142.93.184.210/health

Should see:
```json
{"status":"ok","timestamp":"...","environment":"production"}
```

---

## If Something Goes Wrong

### Rollback Database
```bash
ssh root@142.93.184.210
pm2 stop blescanner-backend
BACKUP_FILE=$(ls -t /var/backups/blescanner_backup_*.sql | head -1)
psql -U blescanner_user -d blescanner < $BACKUP_FILE
pm2 start blescanner-backend
```

### Rollback Code
```bash
ssh root@142.93.184.210
cd /var/www/blescanner-backend
pm2 stop blescanner-backend
rm -rf server/
tar -xzf /var/backups/blescanner_code_backup_*.tar.gz
pm2 start blescanner-backend
```

### Check Logs
```bash
ssh root@142.93.184.210
pm2 logs blescanner-backend --err
```

---

## Common Issues

### "pool.connect is not a function"
- Already fixed in KeyService.js
- If you see this, the old code is still running

### "authenticateToken is not defined"
- Already fixed in routes/keys.js
- If you see this, the old code is still running

### "message_text NOT NULL constraint"
- Already fixed in migration
- Migration adds `ALTER TABLE messages ALTER COLUMN message_text DROP NOT NULL;`

---

**Ready to deploy!** Start with Step 1 above. 🚀
