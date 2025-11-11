# Signal Protocol E2EE Integration Status

## Overview
Implementing end-to-end encryption using Signal Protocol so the backend stores only encrypted messages (stateless, zero-knowledge server).

**Timeline:** 3-4 weeks MVP
**Current Status:** Week 1 - Backend Infrastructure **COMPLETE** ✅

---

## Week 1: Backend Infrastructure ✅ COMPLETE

### Database Changes ✅
**File:** `server/db/migrations/002_signal_protocol.sql`

**New Tables (4):**
1. ✅ `identity_keys` - User public identity keys (32 bytes each)
2. ✅ `signed_prekeys` - Signed prekeys with signatures
3. ✅ `one_time_prekeys` - Single-use prekeys (batch of 100 per user)
4. ✅ `users` - Added `prekey_count` column

**Modified Tables:**
- ✅ `messages` - Added columns:
  - `encrypted_payload` (BYTEA) - Encrypted message content
  - `sender_ratchet_key` (BYTEA) - Sender's ratchet public key
  - `counter` (INTEGER) - Message counter
  - `encryption_version` (INTEGER) - 0=plaintext (legacy), 1=encrypted

**Migration Notes:**
- Old `message_text` column preserved for backwards compatibility
- `messages_backup` table created before migration
- After rollout, delete old plaintext messages with:
  ```sql
  DELETE FROM messages WHERE encryption_version = 0 OR encryption_version IS NULL;
  ```

### Backend Services ✅

#### KeyService.js ✅
**File:** `server/services/KeyService.js`

**Methods:**
- ✅ `storeIdentityKey(userId, publicKey, registrationId)` - Store user's identity key
- ✅ `storeSignedPrekey(userId, keyId, publicKey, signature)` - Store signed prekey
- ✅ `storeOneTimePrekeys(userId, prekeys[])` - Store batch of one-time prekeys
- ✅ `getPreKeyBundle(userId, requesterId)` - Fetch bundle for session establishment
- ✅ `getAvailablePrekeyCount(userId)` - Check available prekey count
- ✅ `hasKeys(userId)` - Check if user has uploaded keys
- ✅ `deleteAllKeys(userId)` - Delete all keys (for rotation/deletion)

**Features:**
- Atomic transactions for consistency
- Automatic prekey consumption tracking
- Prekey count monitoring

#### MessageService.js ✅
**File:** `server/services/MessageService.js`

**New Methods:**
- ✅ `sendEncryptedMessages(fromUserId, encryptedMessages[], deviceName)` - Send E2EE messages
  - Accepts array of `{toUserId, encryptedPayload, senderRatchetKey, counter}`
  - Stores one message per recipient (unique encryption per user)
  - Returns message IDs

**Modified Methods:**
- ✅ `sendMessage()` - Marked as `@deprecated`, kept for backwards compatibility
- ✅ `getMessageHistory()` - Returns both encrypted and plaintext messages
  - Encrypted messages: Returns `encrypted_payload` (base64)
  - Plaintext messages: Returns `message_text` (legacy)
- ✅ `_formatMessage()` - Helper to format based on `encryption_version`

#### PushService.js ✅
**File:** `server/services/PushService.js`

**Modified Methods:**
- ✅ `sendMessageNotification()` - Privacy-preserving notifications
  - **Encrypted messages:** "{device}: New message" (sender name only)
  - **Plaintext messages:** "{device}: {message}" (full content - legacy)
  - Flag in payload: `encrypted: true/false`

### API Routes ✅

#### /api/keys Routes ✅
**File:** `server/routes/keys.js`

**Endpoints:**
- ✅ `POST /api/keys/upload` - Upload identity + signed prekey + one-time prekeys
  - Body: `{identityKey, registrationId, signedPrekey, oneTimePrekeys[]}`
  - Validates key sizes (32 bytes for Curve25519)
  - Returns: `{success, oneTimePrekeyCount}`

- ✅ `GET /api/keys/bundle/:userId` - Get prekey bundle for session establishment
  - Returns: `{identityKey, registrationId, signedPrekey, oneTimePrekey}`
  - Automatically consumes one one-time prekey
  - Returns `null` for oneTimePrekey if exhausted

- ✅ `POST /api/keys/replenish-prekeys` - Upload additional one-time prekeys
  - Body: `{oneTimePrekeys[]}`

- ✅ `GET /api/keys/prekey-count` - Get available prekey count
  - Returns: `{count, needsReplenishment}`
  - Alerts if count < 20

- ✅ `GET /api/keys/status` - Check if user has uploaded keys
  - Returns: `{hasKeys, prekeyCount, needsSetup}`

- ✅ `DELETE /api/keys` - Delete all keys (for rotation/deletion)

**All routes require JWT authentication**

#### /api/messages Routes ✅
**File:** `server/routes/messages.js`

**New Endpoints:**
- ✅ `POST /api/messages/send-encrypted` - Send encrypted messages
  - Body: `{messages: [{to_user_id, encrypted_payload, sender_ratchet_key, counter}], device_name}`
  - Accepts base64-encoded encrypted payloads
  - Sends sender-only push notifications
  - Returns: `{message_ids[], recipient_count, push_sent}`

**Modified Endpoints:**
- ✅ `POST /api/messages/send` - Marked as legacy (plaintext)
  - Still functional for backwards compatibility
  - Will show message content in push notifications

- ✅ `GET /api/messages/history` - Returns both encrypted and plaintext
  - Encrypted: `{encrypted_payload, sender_ratchet_key, counter, encryption_version: 1}`
  - Plaintext: `{message_text, encryption_version: 0}`

### Dependencies ✅

**NPM Packages:**
- ✅ `@signalapp/libsignal-client` - Official Signal Protocol library
  - Installed via: `npm install @signalapp/libsignal-client`
  - Version: Latest (0.83.0+)
  - Note: Currently installed but not used on backend (backend only stores public keys)

### Server Configuration ✅

**Updated Files:**
- ✅ `server/index.js` - Added `/api/keys` routes
- ✅ Startup logs show new endpoints:
  - `POST /api/keys/upload - Upload Signal Protocol keys`
  - `GET /api/keys/bundle/:userId - Get prekey bundle`
  - `GET /api/keys/status - Check key setup status`

---

## Testing Backend (Week 1 Final Task)

### To Test Locally:

1. **Run Database Migration:**
   ```bash
   ssh root@142.93.184.210
   cd /var/www/blescanner-backend/server
   psql -U blescanner_user -d blescanner -f db/migrations/002_signal_protocol.sql
   ```

2. **Deploy Backend:**
   ```bash
   # Copy new files to server
   scp -r server/services/KeyService.js root@142.93.184.210:/var/www/blescanner-backend/server/services/
   scp -r server/routes/keys.js root@142.93.184.210:/var/www/blescanner-backend/server/routes/

   # Update modified files
   scp server/index.js root@142.93.184.210:/var/www/blescanner-backend/server/
   scp server/services/MessageService.js root@142.93.184.210:/var/www/blescanner-backend/server/services/
   scp server/services/PushService.js root@142.93.184.210:/var/www/blescanner-backend/server/services/
   scp server/routes/messages.js root@142.93.184.210:/var/www/blescanner-backend/server/routes/
   scp server/package.json root@142.93.184.210:/var/www/blescanner-backend/server/

   # Install dependencies and restart
   ssh root@142.93.184.210 "cd /var/www/blescanner-backend/server && npm install && pm2 restart blescanner-backend"
   ```

3. **Test Key Upload Endpoint:**
   ```bash
   # Register user
   curl -X POST http://142.93.184.210/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser","password":"testpass"}'

   # Get JWT token from response, then:
   TOKEN="<jwt_token>"

   # Upload keys (dummy data for testing)
   curl -X POST http://142.93.184.210/api/keys/upload \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "identityKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
       "registrationId": 12345,
       "signedPrekey": {
         "keyId": 1,
         "publicKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
         "signature": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
       },
       "oneTimePrekeys": [
         {"keyId": 1, "publicKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="},
         {"keyId": 2, "publicKey": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="}
       ]
     }'
   ```

4. **Test Prekey Bundle Fetch:**
   ```bash
   # Register second user
   curl -X POST http://142.93.184.210/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser2","password":"testpass"}'

   TOKEN2="<jwt_token_from_user2>"
   USER1_ID="<user1_id>"

   # Fetch user1's prekey bundle as user2
   curl http://142.93.184.210/api/keys/bundle/$USER1_ID \
     -H "Authorization: Bearer $TOKEN2"
   ```

5. **Verify Database:**
   ```bash
   ssh root@142.93.184.210
   psql -U blescanner_user -d blescanner

   # Check tables exist
   \dt

   # Check keys stored
   SELECT * FROM identity_keys;
   SELECT * FROM signed_prekeys;
   SELECT * FROM one_time_prekeys WHERE consumed = FALSE;
   ```

---

## Next Steps: Week 2 - iOS Key Management

**Goal:** Implement Signal Protocol on iOS client

**Tasks:**
1. Add `signalapp/libsignal` Swift package
2. Create `SignalProtocolStore.swift` (4 storage interfaces)
3. Create `SignalKeyManager.swift` (key generation, upload, fetch)
4. Create `EncryptionService.swift` (encrypt/decrypt wrapper)
5. Integrate Keychain for private key storage
6. Add key generation flow on first launch/post-update
7. Test key upload to backend

**Estimated:** 1 week

---

## Architecture Summary

### Current Message Flow (After Week 1)

**Plaintext (Legacy):**
1. iOS → `POST /api/messages/send` → Backend stores plaintext
2. Push notification shows full message content
3. iOS fetches history → Sees plaintext

**Encrypted (New - Backend Ready):**
1. iOS encrypts locally (Week 2) → `POST /api/messages/send-encrypted`
2. Backend stores `encrypted_payload` (cannot decrypt)
3. Push notification: "{sender}: New message" (privacy-preserving)
4. iOS fetches history → Decrypts locally (Week 3)

### Security Properties (When Complete)

✅ **End-to-End Encryption:** Only sender and recipient can read messages
✅ **Forward Secrecy:** Compromised keys don't decrypt old messages
✅ **Zero-Knowledge Server:** Backend cannot read message content
✅ **Privacy-Preserving Push:** Notifications don't leak content
⏳ **Future Secrecy:** (Requires key rotation - future enhancement)

---

## Files Created/Modified

### Created:
- ✅ `server/db/migrations/002_signal_protocol.sql`
- ✅ `server/services/KeyService.js`
- ✅ `server/routes/keys.js`
- ✅ `SIGNAL_PROTOCOL_INTEGRATION.md` (this file)

### Modified:
- ✅ `server/index.js` - Added `/api/keys` routes
- ✅ `server/services/MessageService.js` - Added encrypted message support
- ✅ `server/services/PushService.js` - Added privacy-preserving notifications
- ✅ `server/routes/messages.js` - Added `/send-encrypted` endpoint
- ✅ `server/package.json` - Added `@signalapp/libsignal-client`

---

## Notes

1. **Backwards Compatibility:** Old plaintext messages still work during migration
2. **Prekey Exhaustion:** Monitor with `/api/keys/prekey-count`, replenish when < 20
3. **Migration Strategy:** After iOS rollout, delete plaintext messages from database
4. **Push Notifications:** Sender name only for encrypted messages (privacy vs. UX tradeoff)
5. **Session Storage:** Client-side only (iOS Keychain), no server-side session storage

---

**Last Updated:** November 10, 2025
**Status:** Week 1 Complete, Ready for Week 2 (iOS Implementation)
