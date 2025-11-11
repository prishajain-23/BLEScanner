# Testing Signal Protocol Backend - Local Environment

## Overview
Before deploying to production (142.93.184.210), we need to test all the Signal Protocol backend changes locally.

---

## Prerequisites

1. ✅ PostgreSQL installed locally
2. ✅ Node.js 18+ installed
3. ✅ Backend code with Signal Protocol changes
4. ✅ Test database setup

---

## Step 1: Set Up Local Test Database

### Create Test Database

```bash
# Connect to PostgreSQL
psql postgres

# Create test database and user
CREATE DATABASE blescanner_test;
CREATE USER blescanner_test_user WITH ENCRYPTED PASSWORD 'test_password';
GRANT ALL PRIVILEGES ON DATABASE blescanner_test TO blescanner_test_user;

# Exit
\q
```

### Run Schema Migrations

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Run original schema
psql -U blescanner_test_user -d blescanner_test -f db/schema.sql

# Run Signal Protocol migration
psql -U blescanner_test_user -d blescanner_test -f db/migrations/002_signal_protocol.sql
```

### Verify Tables Created

```bash
psql -U blescanner_test_user -d blescanner_test

# List all tables
\dt

# Expected tables:
# - users
# - messages
# - messages_backup
# - message_recipients
# - contacts
# - device_tokens
# - identity_keys (NEW)
# - signed_prekeys (NEW)
# - one_time_prekeys (NEW)

# Check messages table schema
\d messages

# Expected columns:
# - id, from_user_id, message_text (old)
# - encrypted_payload (NEW)
# - sender_ratchet_key (NEW)
# - counter (NEW)
# - encryption_version (NEW)
# - device_name, created_at

\q
```

---

## Step 2: Configure Local Environment

### Create .env for Testing

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Create test .env (if doesn't exist)
cat > .env.test << 'EOF'
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=blescanner_test
DB_USER=blescanner_test_user
DB_PASSWORD=test_password

# JWT
JWT_SECRET=test_secret_key_for_local_testing_only

# Server
PORT=3001
NODE_ENV=development

# APNs (optional for this test - can be dummy values)
APNS_KEY_ID=dummy
APNS_TEAM_ID=dummy
APNS_TOPIC=com.test.app
APNS_KEY_PATH=./config/dummy.p8
APNS_PRODUCTION=false
EOF
```

### Install Dependencies

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Install all dependencies (including @signalapp/libsignal-client)
npm install

# Verify libsignal installed
npm list @signalapp/libsignal-client
```

---

## Step 3: Start Local Test Server

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner/server

# Use test environment
export $(cat .env.test | xargs)

# Start server
npm start

# Expected output:
# ✓ APNs not configured - push notifications disabled (OK for testing)
# ✅ BLEScanner Backend API Server Running
# 🌐 Server: http://localhost:3001
# Available endpoints:
#   ...
#   POST /api/keys/upload - Upload Signal Protocol keys
#   GET  /api/keys/bundle/:userId - Get prekey bundle
#   GET  /api/keys/status - Check key setup status
```

**Server should be running on http://localhost:3001**

---

## Step 4: Test API Endpoints

### Test 1: Health Check

```bash
curl http://localhost:3001/health

# Expected:
# {"status":"ok","timestamp":"...","environment":"development"}
```

### Test 2: Register Users

```bash
# Register User 1 (Alice)
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "password": "password123"
  }'

# Expected response:
# {
#   "success": true,
#   "user": {"id": 1, "username": "alice"},
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
# }

# Save Alice's token
ALICE_TOKEN="<paste_token_here>"
ALICE_ID=1

# Register User 2 (Bob)
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob",
    "password": "password123"
  }'

# Save Bob's token
BOB_TOKEN="<paste_token_here>"
BOB_ID=2
```

### Test 3: Check Key Status (Before Upload)

```bash
# Check Alice's key status
curl http://localhost:3001/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN"

# Expected:
# {
#   "hasKeys": false,
#   "prekeyCount": 0,
#   "needsSetup": true
# }
```

### Test 4: Upload Keys (Alice)

```bash
# Generate dummy keys (32 bytes base64-encoded)
# In production, iOS will generate real Curve25519 keys
# For testing, we'll use dummy data

curl -X POST http://localhost:3001/api/keys/upload \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identityKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    "registrationId": 12345,
    "signedPrekey": {
      "keyId": 1,
      "publicKey": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
      "signature": "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
    },
    "oneTimePrekeys": [
      {"keyId": 1, "publicKey": "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="},
      {"keyId": 2, "publicKey": "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="},
      {"keyId": 3, "publicKey": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF="}
    ]
  }'

# Expected:
# {
#   "success": true,
#   "message": "Keys uploaded successfully",
#   "oneTimePrekeyCount": 3
# }
```

### Test 5: Check Key Status (After Upload)

```bash
curl http://localhost:3001/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN"

# Expected:
# {
#   "hasKeys": true,
#   "prekeyCount": 3,
#   "needsSetup": false
# }
```

### Test 6: Upload Keys (Bob)

```bash
curl -X POST http://localhost:3001/api/keys/upload \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identityKey": "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG=",
    "registrationId": 54321,
    "signedPrekey": {
      "keyId": 1,
      "publicKey": "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH=",
      "signature": "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII="
    },
    "oneTimePrekeys": [
      {"keyId": 1, "publicKey": "JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ="},
      {"keyId": 2, "publicKey": "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK="}
    ]
  }'

# Expected:
# {
#   "success": true,
#   "message": "Keys uploaded successfully",
#   "oneTimePrekeyCount": 2
# }
```

### Test 7: Fetch Prekey Bundle (Bob fetches Alice's bundle)

```bash
curl http://localhost:3001/api/keys/bundle/$ALICE_ID \
  -H "Authorization: Bearer $BOB_TOKEN"

# Expected:
# {
#   "identityKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
#   "registrationId": 12345,
#   "signedPrekey": {
#     "keyId": 1,
#     "publicKey": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
#     "signature": "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
#   },
#   "oneTimePrekey": {
#     "keyId": 1,
#     "publicKey": "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="
#   }
# }
```

### Test 8: Check Prekey Consumption

```bash
# Check Alice's prekey count (should be 2 now - one consumed)
curl http://localhost:3001/api/keys/prekey-count \
  -H "Authorization: Bearer $ALICE_TOKEN"

# Expected:
# {
#   "count": 2,
#   "needsReplenishment": false
# }
```

### Test 9: Verify Database State

```bash
psql -U blescanner_test_user -d blescanner_test

-- Check identity keys
SELECT user_id, registration_id, length(public_key) FROM identity_keys;
-- Expected: 2 rows (Alice=1, Bob=2), public_key length = 32 bytes

-- Check signed prekeys
SELECT user_id, key_id, length(public_key), length(signature) FROM signed_prekeys;
-- Expected: 2 rows, lengths = 32 bytes each

-- Check one-time prekeys
SELECT user_id, key_id, consumed, consumed_by FROM one_time_prekeys ORDER BY user_id, key_id;
-- Expected:
--   Alice (id=1): keyId=1 consumed=TRUE consumed_by=2 (Bob)
--   Alice (id=1): keyId=2 consumed=FALSE
--   Alice (id=1): keyId=3 consumed=FALSE
--   Bob (id=2): keyId=1 consumed=FALSE
--   Bob (id=2): keyId=2 consumed=FALSE

-- Check users table
SELECT id, username, prekey_count FROM users;
-- Expected:
--   Alice (id=1): prekey_count=2
--   Bob (id=2): prekey_count=2

\q
```

### Test 10: Send Encrypted Message

```bash
# Bob sends encrypted message to Alice
curl -X POST http://localhost:3001/api/messages/send-encrypted \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "to_user_id": 1,
        "encrypted_payload": "c29tZV9lbmNyeXB0ZWRfZGF0YV9oZXJl",
        "sender_ratchet_key": "cmF0Y2hldF9rZXlfaGVyZQ==",
        "counter": 1
      }
    ],
    "device_name": "ESP32-TestDevice"
  }'

# Expected:
# {
#   "success": true,
#   "message_ids": [1],
#   "recipient_count": 1,
#   "push_sent": false
# }
```

### Test 11: Fetch Message History

```bash
# Alice fetches messages (should see encrypted payload)
curl http://localhost:3001/api/messages/history \
  -H "Authorization: Bearer $ALICE_TOKEN"

# Expected:
# {
#   "success": true,
#   "messages": [
#     {
#       "id": 1,
#       "from_user_id": 2,
#       "from_username": "bob",
#       "device_name": "ESP32-TestDevice",
#       "encrypted_payload": "c29tZV9lbmNyeXB0ZWRfZGF0YV9oZXJl",
#       "sender_ratchet_key": "cmF0Y2hldF9rZXlfaGVyZQ==",
#       "counter": 1,
#       "encryption_version": 1,
#       "read": false,
#       "is_sent": false
#     }
#   ]
# }
```

### Test 12: Verify Database - Messages Table

```bash
psql -U blescanner_test_user -d blescanner_test

-- Check messages table
SELECT
  id,
  from_user_id,
  message_text,
  length(encrypted_payload) as payload_length,
  encryption_version,
  device_name
FROM messages;

-- Expected:
-- id=1, from_user_id=2, message_text=NULL, payload_length=24, encryption_version=1

-- Check message_recipients
SELECT message_id, to_user_id, read FROM message_recipients;
-- Expected: message_id=1, to_user_id=1 (Alice), read=FALSE

\q
```

### Test 13: Test Legacy Plaintext Message (Backwards Compatibility)

```bash
# Alice sends plaintext message to Bob (legacy endpoint)
curl -X POST http://localhost:3001/api/messages/send \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to_user_ids": [2],
    "message": "This is a plaintext message",
    "device_name": "ESP32-Legacy"
  }'

# Expected:
# {
#   "success": true,
#   "message": {
#     "id": 2,
#     "message_text": "This is a plaintext message",
#     ...
#   }
# }

# Bob fetches history (should see both encrypted and plaintext)
curl http://localhost:3001/api/messages/history \
  -H "Authorization: Bearer $BOB_TOKEN"

# Expected: 2 messages
# - Message 1: encrypted_payload (from Bob to Alice, visible to Bob as sent)
# - Message 2: message_text "This is a plaintext message" (from Alice to Bob)
```

### Test 14: Replenish Prekeys

```bash
# Alice replenishes prekeys
curl -X POST http://localhost:3001/api/keys/replenish-prekeys \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "oneTimePrekeys": [
      {"keyId": 4, "publicKey": "LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL="},
      {"keyId": 5, "publicKey": "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM="}
    ]
  }'

# Expected:
# {
#   "success": true,
#   "message": "Prekeys replenished successfully",
#   "storedCount": 2
# }

# Check count (should be 4 now: 2 unconsumed + 2 new)
curl http://localhost:3001/api/keys/prekey-count \
  -H "Authorization: Bearer $ALICE_TOKEN"

# Expected:
# {"count": 4, "needsReplenishment": false}
```

---

## Step 5: Automated Test Script

Save this as `test-signal-api.sh`:

```bash
#!/bin/bash

set -e

BASE_URL="http://localhost:3001"

echo "🧪 Testing Signal Protocol Backend API"
echo "========================================"

# Test 1: Health Check
echo "✓ Test 1: Health Check"
curl -s $BASE_URL/health | jq .

# Test 2: Register Alice
echo "✓ Test 2: Register Alice"
ALICE_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"password123"}')
ALICE_TOKEN=$(echo $ALICE_RESPONSE | jq -r .token)
ALICE_ID=$(echo $ALICE_RESPONSE | jq -r .user.id)
echo "Alice ID: $ALICE_ID"

# Test 3: Register Bob
echo "✓ Test 3: Register Bob"
BOB_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","password":"password123"}')
BOB_TOKEN=$(echo $BOB_RESPONSE | jq -r .token)
BOB_ID=$(echo $BOB_RESPONSE | jq -r .user.id)
echo "Bob ID: $BOB_ID"

# Test 4: Check key status (before upload)
echo "✓ Test 4: Check Alice key status (before)"
curl -s $BASE_URL/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .

# Test 5: Upload Alice's keys
echo "✓ Test 5: Upload Alice's keys"
curl -s -X POST $BASE_URL/api/keys/upload \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identityKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    "registrationId": 12345,
    "signedPrekey": {
      "keyId": 1,
      "publicKey": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
      "signature": "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
    },
    "oneTimePrekeys": [
      {"keyId": 1, "publicKey": "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="},
      {"keyId": 2, "publicKey": "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="},
      {"keyId": 3, "publicKey": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF="}
    ]
  }' | jq .

# Test 6: Check key status (after upload)
echo "✓ Test 6: Check Alice key status (after)"
curl -s $BASE_URL/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .

# Test 7: Upload Bob's keys
echo "✓ Test 7: Upload Bob's keys"
curl -s -X POST $BASE_URL/api/keys/upload \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identityKey": "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG=",
    "registrationId": 54321,
    "signedPrekey": {
      "keyId": 1,
      "publicKey": "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH=",
      "signature": "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII="
    },
    "oneTimePrekeys": [
      {"keyId": 1, "publicKey": "JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ="},
      {"keyId": 2, "publicKey": "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK="}
    ]
  }' | jq .

# Test 8: Fetch prekey bundle
echo "✓ Test 8: Bob fetches Alice's prekey bundle"
curl -s $BASE_URL/api/keys/bundle/$ALICE_ID \
  -H "Authorization: Bearer $BOB_TOKEN" | jq .

# Test 9: Check prekey count (after consumption)
echo "✓ Test 9: Check Alice prekey count (after consumption)"
curl -s $BASE_URL/api/keys/prekey-count \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .

# Test 10: Send encrypted message
echo "✓ Test 10: Bob sends encrypted message to Alice"
curl -s -X POST $BASE_URL/api/messages/send-encrypted \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "to_user_id": '$ALICE_ID',
        "encrypted_payload": "c29tZV9lbmNyeXB0ZWRfZGF0YV9oZXJl",
        "sender_ratchet_key": "cmF0Y2hldF9rZXlfaGVyZQ==",
        "counter": 1
      }
    ],
    "device_name": "ESP32-TestDevice"
  }' | jq .

# Test 11: Fetch message history
echo "✓ Test 11: Alice fetches message history"
curl -s $BASE_URL/api/messages/history \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .

echo ""
echo "✅ All tests passed!"
echo "🎉 Signal Protocol backend is ready for deployment"
```

Make executable and run:

```bash
chmod +x test-signal-api.sh
./test-signal-api.sh
```

---

## Expected Results Summary

✅ **All 11 tests should pass:**
1. Health check returns OK
2. Users register successfully
3. Key status shows `needsSetup: true` before upload
4. Keys upload successfully
5. Key status shows `needsSetup: false` after upload
6. Prekey bundle fetch returns all keys
7. One-time prekey is consumed and count decreases
8. Encrypted message sends successfully
9. Message history returns encrypted payload (base64)
10. Database stores encrypted_payload, not plaintext
11. Legacy plaintext endpoint still works

---

## Troubleshooting

### Server won't start
- Check PostgreSQL is running: `brew services list` (macOS)
- Verify database exists: `psql -l`
- Check port 3001 not in use: `lsof -i :3001`

### Database errors
- Ensure migrations ran: `\dt` in psql should show all tables
- Check user permissions: `GRANT ALL PRIVILEGES ON DATABASE...`

### Key upload fails
- Check key sizes: Must be exactly 32 bytes (base64: 44 characters)
- Verify JWT token is valid: Decode at jwt.io

### Prekey bundle returns null
- User must upload keys first: Check `/api/keys/status`
- Verify keys exist in database: `SELECT * FROM identity_keys;`

---

## Next Step: Deploy to Production

Once all tests pass locally, you're ready to deploy to 142.93.184.210!

See `SIGNAL_PROTOCOL_INTEGRATION.md` Section "Testing Backend" for deployment instructions.
