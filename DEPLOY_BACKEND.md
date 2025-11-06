# Backend Deployment Guide

## Quick Deploy to Production

### Manual File Update (Recommended)

Since SSH keys aren't configured, manually copy the updated file:

```bash
# 1. Copy the updated MessageService.js to your local machine
scp server/services/MessageService.js root@142.93.184.210:/tmp/

# 2. SSH to the server
ssh root@142.93.184.210

# 3. Move the file to the correct location
mv /tmp/MessageService.js /var/www/blescanner-backend/server/services/

# 4. Restart the service
pm2 restart blescanner-backend

# 5. Verify it's running
pm2 logs blescanner-backend --lines 50
```

### Alternative: Git Pull (Requires Git Setup)

If you have git configured on the server:

```bash
# SSH to server
ssh root@142.93.184.210

# Navigate to app directory
cd /var/www/blescanner-backend/server

# Pull latest changes
git fetch origin
git checkout messages
git pull origin messages

# Restart service
pm2 restart blescanner-backend

# Check logs
pm2 logs blescanner-backend --lines 20
```

---

## What Changed

**File**: `server/services/MessageService.js`

**Change**: The `getMessageHistory()` function now includes recipient usernames for sent messages.

**SQL Query Update**:
```sql
-- Before: Just returned basic message info
SELECT m.id, m.from_user_id, u.username as from_username, ...

-- After: Includes recipients via ARRAY_AGG
SELECT m.id, m.from_user_id, u.username as from_username,
       ARRAY_AGG(ru.username) as to_usernames, ...
FROM messages m
LEFT JOIN message_recipients mr ON m.id = mr.message_id
LEFT JOIN users ru ON mr.to_user_id = ru.id
GROUP BY m.id, u.username
```

---

## Testing After Deployment

1. **Send a test message** from alice_test to bob_test
2. **View message history** in alice_test's app
3. **Verify** it shows "To: bob_test" (not "Sent")

**Test with curl:**
```bash
# Login as alice_test
curl -X POST http://142.93.184.210/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"alice_test","password":"yourpassword"}'

# Copy the token from response

# Get message history
curl http://142.93.184.210/api/messages/history?limit=5 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Look for "to_usernames" field in sent messages
```

Expected response for sent messages:
```json
{
  "id": 123,
  "from_username": "alice_test",
  "is_sent": true,
  "to_usernames": ["bob_test"],  // ← NEW FIELD
  "message_text": "...",
  ...
}
```

---

## Rollback (If Needed)

If there are issues, revert to the previous version:

```bash
# On server
cd /var/www/blescanner-backend/server/services

# Restore from git
git checkout HEAD~1 -- MessageService.js

# Restart
pm2 restart blescanner-backend
```

---

## Server Info

- **Server IP**: 142.93.184.210
- **App Path**: /var/www/blescanner-backend/server
- **Process**: blescanner-backend (PM2)
- **Port**: 3000 (proxied via Nginx on port 80)

---

**Last Updated**: November 6, 2025
**Commit**: aa9b3cc
**Status**: Ready to deploy
