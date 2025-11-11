# Deploy Signal Protocol to Production (142.93.184.210)

## Pre-Deployment Checklist

✅ Local tests passed (all 14 tests)
✅ Database migration tested locally
✅ Code fixes applied:
- Fixed `authenticateToken` import in routes/keys.js
- Fixed `pool` import in services/KeyService.js
- Made `message_text` nullable in migration

---

## Step 1: Backup Production Database

```bash
# SSH to production server
ssh root@142.93.184.210

# Create backup directory if doesn't exist
mkdir -p /var/backups

# Backup database
pg_dump -U blescanner_user blescanner > /var/backups/blescanner_backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup created
ls -lh /var/backups/blescanner_backup_*.sql | tail -1

# Exit SSH
exit
```

---

## Step 2: Deploy Files to Production

### Option A: Deploy from Local Machine (Recommended)

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner

# Create deployment package
tar -czf signal-protocol-deploy.tar.gz \
  server/db/migrations/002_signal_protocol.sql \
  server/services/KeyService.js \
  server/services/MessageService.js \
  server/services/PushService.js \
  server/routes/keys.js \
  server/routes/messages.js \
  server/index.js \
  server/package.json

# Copy to server
scp signal-protocol-deploy.tar.gz root@142.93.184.210:/tmp/

# SSH to server and extract
ssh root@142.93.184.210

cd /var/www/blescanner-backend/server

# Backup current code
tar -czf /var/backups/blescanner_code_backup_$(date +%Y%m%d_%H%M%S).tar.gz .

# Extract new code
tar -xzf /tmp/signal-protocol-deploy.tar.gz

# Verify files extracted
ls -la db/migrations/002_signal_protocol.sql
ls -la services/KeyService.js
ls -la routes/keys.js
```

### Option B: Deploy via Git (Alternative)

```bash
ssh root@142.93.184.210

cd /var/www/blescanner-backend

# Backup current code
tar -czf /var/backups/blescanner_code_backup_$(date +%Y%m%d_%H%M%S).tar.gz server/

# Pull latest changes (if using git)
git pull origin signal

# Or manually copy files if not using git
```

---

## Step 3: Run Database Migration

```bash
# Still on production server (142.93.184.210)
cd /var/www/blescanner-backend/server

# Run migration
psql -U blescanner_user -d blescanner -f db/migrations/002_signal_protocol.sql

# Verify tables created
psql -U blescanner_user -d blescanner -c "\dt" | grep -E "(identity_keys|signed_prekeys|one_time_prekeys)"

# Expected output:
# public | identity_keys      | table | blescanner_user
# public | one_time_prekeys   | table | blescanner_user
# public | signed_prekeys     | table | blescanner_user

# Verify messages table updated
psql -U blescanner_user -d blescanner -c "\d messages" | grep -E "(encrypted_payload|encryption_version)"

# Expected output:
#  encrypted_payload  | bytea   |
#  encryption_version | integer | default 1
```

---

## Step 4: Install Dependencies

```bash
# Still on production server
cd /var/www/blescanner-backend/server

# Install new dependencies (@signalapp/libsignal-client)
npm install

# Verify libsignal installed
npm list @signalapp/libsignal-client

# Expected output:
# blescanner-backend@1.0.0 /var/www/blescanner-backend/server
# └── @signalapp/libsignal-client@0.86.2
```

---

## Step 5: Restart Server

```bash
# Check current status
pm2 status

# Restart backend
pm2 restart blescanner-backend

# Check logs for errors
pm2 logs blescanner-backend --lines 50

# Expected in logs:
# ✓ APNs provider initialized
# ✅ BLEScanner Backend API Server Running
# POST /api/keys/upload - Upload Signal Protocol keys
# GET  /api/keys/bundle/:userId - Get prekey bundle
```

---

## Step 6: Test Production Deployment

### Test 1: Health Check

```bash
curl http://142.93.184.210/health

# Expected:
# {"status":"ok","timestamp":"...","environment":"production"}
```

### Test 2: Register Test User

```bash
curl -X POST http://142.93.184.210/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"signal_test_user","password":"testpass123"}'

# Save token
TOKEN="<paste_token_here>"
```

### Test 3: Check Key Status

```bash
curl http://142.93.184.210/api/keys/status \
  -H "Authorization: Bearer $TOKEN"

# Expected:
# {"hasKeys":false,"prekeyCount":0,"needsSetup":true}
```

### Test 4: Upload Keys

```bash
curl -X POST http://142.93.184.210/api/keys/upload \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identityKey": "7dl9633gceQQktCQtAWEiVRs6Co20F4GCZFYRVfyAno=",
    "registrationId": 12345,
    "signedPrekey": {
      "keyId": 1,
      "publicKey": "5RD+rs443Lo2QZewhVV/3DfxPasaHLpGaC97gNp/Fq0=",
      "signature": "ksFqZYiioUJ9ffkGx37g7DkSGp/htSBf2cXdDVIMVOnJl4ynpi/zEfn/3zKZagqXoqY7xwJzy36PRUqI4AKpNA=="
    },
    "oneTimePrekeys": [
      {"keyId": 1, "publicKey": "aixDVJm4acbHnQ8gAvAMtgUCHamy0kSOyFUz6NNX5OE="},
      {"keyId": 2, "publicKey": "gVKMgiC2+zyo6JaOnCpQ6nPj95G1oDwAzj7Jcmd9sFs="}
    ]
  }'

# Expected:
# {"success":true,"message":"Keys uploaded successfully","oneTimePrekeyCount":2}
```

### Test 5: Verify Database

```bash
ssh root@142.93.184.210

psql -U blescanner_user -d blescanner

-- Check keys stored
SELECT user_id, registration_id, length(public_key) FROM identity_keys;
SELECT user_id, key_id, length(public_key) FROM signed_prekeys;
SELECT user_id, key_id, consumed FROM one_time_prekeys;

-- Should see 1 user with keys
\q
exit
```

---

## Step 7: Run Full Test Suite on Production

Create test script on your local machine:

```bash
# Copy and modify test script for production
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Edit test script to use production URL
sed 's|http://localhost:3001|http://142.93.184.210|g' test-signal-api-fixed.sh > test-production.sh

chmod +x test-production.sh

# Run production tests
./test-production.sh
```

---

## Rollback Plan (If Needed)

If something goes wrong:

```bash
ssh root@142.93.184.210

# Stop server
pm2 stop blescanner-backend

# Restore database
BACKUP_FILE=$(ls -t /var/backups/blescanner_backup_*.sql | head -1)
psql -U blescanner_user -d blescanner < $BACKUP_FILE

# Restore code
cd /var/www/blescanner-backend
rm -rf server/
tar -xzf /var/backups/blescanner_code_backup_*.tar.gz

# Restart
pm2 start blescanner-backend
```

---

## Post-Deployment Verification

### Check Server Logs

```bash
ssh root@142.93.184.210
pm2 logs blescanner-backend --lines 100
```

### Monitor for Errors

```bash
# Watch logs in real-time
pm2 logs blescanner-backend

# Check for errors
pm2 logs blescanner-backend --err

# Check process status
pm2 status
```

### Verify All Endpoints

```bash
# Health
curl http://142.93.184.210/health

# Auth (existing)
curl -X POST http://142.93.184.210/api/auth/register -H "Content-Type: application/json" -d '{"username":"test","password":"test"}'

# Keys (new)
curl http://142.93.184.210/api/keys/status -H "Authorization: Bearer TOKEN"

# Messages (modified)
curl http://142.93.184.210/api/messages/history -H "Authorization: Bearer TOKEN"
```

---

## Success Criteria

✅ Server restarts without errors
✅ All 4 new tables exist (identity_keys, signed_prekeys, one_time_prekeys, messages_backup)
✅ messages table has new columns (encrypted_payload, sender_ratchet_key, counter, encryption_version)
✅ Key upload endpoint works (/api/keys/upload)
✅ Prekey bundle fetch works (/api/keys/bundle/:userId)
✅ Encrypted message send works (/api/messages/send-encrypted)
✅ Legacy plaintext still works (/api/messages/send)
✅ No errors in pm2 logs

---

## Troubleshooting

### Server won't start
```bash
pm2 logs blescanner-backend --err
# Check for:
# - Missing dependencies (run npm install)
# - Database connection errors (check .env)
# - Syntax errors (check recent changes)
```

### Migration fails
```bash
# Check if tables already exist
psql -U blescanner_user -d blescanner -c "\dt"

# If migration partially ran, drop new tables and retry
psql -U blescanner_user -d blescanner -c "DROP TABLE IF EXISTS identity_keys, signed_prekeys, one_time_prekeys CASCADE;"
```

### Key upload fails
```bash
# Check server logs
pm2 logs blescanner-backend

# Common issues:
# - pool.connect not a function → Check KeyService.js line 12: const { pool } = require(...)
# - authenticateToken undefined → Check routes/keys.js line 10: const authenticateToken = require(...)
```

---

## Files Modified in This Deployment

**Created:**
- `server/db/migrations/002_signal_protocol.sql`
- `server/services/KeyService.js`
- `server/routes/keys.js`

**Modified:**
- `server/index.js` - Added /api/keys routes
- `server/services/MessageService.js` - Added sendEncryptedMessages()
- `server/services/PushService.js` - Updated notification format
- `server/routes/messages.js` - Added /send-encrypted endpoint
- `server/package.json` - Added @signalapp/libsignal-client

---

**Deployment Date:** November 10, 2025
**Version:** Signal Protocol E2EE v1.0
**Tested:** ✅ All 14 tests passed locally

Ready to deploy! 🚀
