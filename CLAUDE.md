# Medal of Freedom (BLEScanner) - Development Guide

## 🚀 CURRENT STATUS - November 12, 2025

**PHASE 1 & 2 COMPLETE ✅** - Production app with backend at `http://142.93.184.210`

**What's Complete:**
- ✅ PostgreSQL database (4 tables, 7 indexes)
- ✅ Node.js/Express API with JWT auth
- ✅ APNs push notifications (Key: N2UGRH67CT, Team: NV97R9Q8MF, Bundle: com.prishajain.medaloffreedom)
- ✅ Production deployment (PM2 + Nginx on 142.93.184.210)
- ✅ iOS app with auth, contacts, messaging, push notifications
- ✅ End-to-end encryption (Signal Protocol with Double Ratchet)
- ✅ Location tracking with reverse geocoding
- ✅ Auto-messaging on BLE connection
- ✅ Message templates with dynamic variables
- ✅ Contact persistence and management
- ✅ Message history with decryption
- ✅ Push notification testing (foreground/background/killed states)

**Recent Updates (Nov 12, 2025):**
- APNs key rotated from X859SFN76P to N2UGRH67CT (previous key compromised)
- Bundle ID updated to com.prishajain.medaloffreedom
- Location tracking added with reverse geocoding (shows "Brooklyn, NY" + Google Maps link)
- Message templates redesigned with line breaks and comprehensive emergency info
- UI rebranded from "BLE"/"BLEScanner" to "Medal of Freedom"
- Contact persistence bug fixed
- Push notification format improved (title: "MOF", body: device name)

**Next Steps:**
- Asset generation (app icons, marketing materials)
- TestFlight beta testing
- App Store submission preparation

---

## Quick Reference

**Goal:** Auto-send encrypted emergency messages when Medal of Freedom BLE device connects

**Key Features:**
- Username/password auth with JWT
- Contact management (username search, select recipients)
- Auto-trigger encrypted messages on BLE connection
- Push notifications to recipients
- Location tracking with human-readable addresses
- Message history with E2E encryption
- Customizable message templates

**Flow:** Medal of Freedom connects → BLEManager detects → LocationService gets GPS → MessagingService encrypts → POST /api/messages/send-encrypted → Backend stores → APNs push → Recipients decrypt

**Stack:**
- Backend: Node.js + Express + PostgreSQL + JWT + bcrypt + node-apn
- iOS: Swift/SwiftUI + URLSession + Keychain + UserNotifications + CoreLocation + CryptoKit
- Encryption: Signal Protocol (X3DH + Double Ratchet)
- Deploy: DigitalOcean + PM2 + Nginx

---

## Database Schema

**Tables:**
- `users` - user accounts, encryption keys (public keys stored)
- `messages` - message records with encrypted payloads
- `message_recipients` - many-to-many relationship
- `contacts` - user contact lists
- `encryption_keys` - public key storage for E2E encryption
- `ratchet_states` - Double Ratchet session state

See `server/db/schema.sql` for full schema.

---

## API Endpoints (Base: `http://142.93.184.210/api`)

**Auth:**
- POST `/auth/register` - {username, password} → {user, token}
- POST `/auth/login` - {username, password} → {user, token}

**Users:**
- GET `/users/search?q=` - Search usernames
- GET `/users/me` - Get profile

**Contacts:**
- POST `/contacts/add` - {contact_username}
- GET `/contacts` - List contacts
- DELETE `/contacts/:id` - Remove contact

**Messages:**
- POST `/messages/send-encrypted` - {messages: [{to_user_id, encrypted_payload, sender_ratchet_key, counter}], device_name}
- GET `/messages/history?limit=50&offset=0` - Get history (encrypted messages included)
- POST `/messages/:id/read` - Mark as read

**Devices:**
- POST `/devices/register-push` - {device_token, platform}
- DELETE `/devices/unregister-push`

**Encryption:**
- POST `/encryption/upload-keys` - {identity_key, signed_prekey, prekey_signature, one_time_prekeys[]}
- POST `/encryption/fetch-keys` - {user_ids[]} → Returns public keys for encryption

All endpoints (except auth) require `Authorization: Bearer <token>` header.

---

## iOS App Structure

**Services:**
- `APIClient.swift` - HTTP client with JWT auth
- `AuthService.swift` - Login/logout, token management
- `ContactService.swift` - Contact CRUD, selection persistence
- `MessagingService.swift` - Send messages, fetch history, encryption integration
- `LocationService.swift` - CoreLocation, reverse geocoding (city/state + GPS link)
- `PushNotificationService.swift` - APNs registration, notification handling
- `CryptoKeyManager.swift` - Key generation, storage, upload
- `CryptoEncryptionService.swift` - Signal Protocol implementation (encrypt/decrypt)
- `BLEManager.swift` - Bluetooth scanning, auto-messaging trigger

**Views:**
- `BLEScannerApp.swift` - App entry, auth gate, service initialization
- `MainTabView.swift` - Tab navigation (Connections, Messages, Settings)
- `AuthView.swift` / `LoginView.swift` / `RegisterView.swift` - Authentication UI
- `ContactListView.swift` / `AddContactView.swift` - Contact management
- `MessagesTabView.swift` / `MessageHistoryView.swift` - Message display
- `MessagingSettingsView.swift` - Auto-messaging toggle, templates, contacts, test encryption
- `SettingsTabView.swift` - App settings

**Models:**
- `User.swift` - User account model
- `Contact.swift` - Contact model
- `Message.swift` - Message model with encryption fields
- `APIModels.swift` - Request/response models

---

## Message Templates

**Variables Available:**
- `{date}` - Current date (abbreviated format, e.g., "Nov 12, 2025")
- `{time}` - Current time (short format, e.g., "3:45 PM")
- `{location}` - Reverse geocoded location with GPS link (e.g., "Brooklyn, NY - https://maps.google.com/?q=40.748,-73.985")
- `{device}` - Device name (always "Medal of Freedom")

**Template Format:**
Templates use `\n` for line breaks and `____` as user-fillable placeholders.

**Sample Template (Full ICE Encounter):**
```
I've been stopped by ICE on {date} at {time}.
Location: {location}

Find me using the ICE locator at https://locator.ice.gov/odls

My A-number is ____.
My legal documents are at ____. Please get them and contact my lawyer ____.

I entrust short-term guardianship of my children to ____. Please pick them up from school/daycare immediately and make any needed medical or legal decisions for them.

My next court date is ____.
Please notify my workplace at ____.
My medications are ____.

Please take care of my pets at ____.
My bank account information is with ____.
My rent/mortgage is due on ____.
```

**Implementation:**
- Default template: `@AppStorage("messageTemplate")` in MessagingSettingsView.swift
- Template substitution: MessagingService.swift `sendConnectionMessage()`
- Location fetch: LocationService.swift `getCurrentLocation()`
- Preview: MessagingSettingsView.swift `previewMessage` computed property

---

## Location Tracking

**Implementation:** `LocationService.swift`

**Features:**
- Requests "When In Use" location authorization
- Uses `CLLocationManager` for GPS coordinates
- Reverse geocoding with `CLGeocoder` to get city/state
- Fallback to raw coordinates if geocoding fails
- Format: "Brooklyn, NY - https://maps.google.com/?q=40.748817,-73.985428"

**Permissions Required (Info.plist):**
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription` (if needed)

**Accuracy:** 6 decimal places (~0.1 meter precision)

**Integration:**
1. `BLEScannerApp.swift` - Requests permissions on login
2. `MessagingService.swift` - Fetches location before sending message
3. Template variables - `{location}` replaced with formatted string

---

## Encryption (Signal Protocol)

**Implementation:**
- `CryptoKeyManager.swift` - Key generation and storage
- `CryptoEncryptionService.swift` - Encryption/decryption logic

**Protocol:**
- X3DH (Extended Triple Diffie-Hellman) for initial key exchange
- Double Ratchet for forward secrecy
- Keys stored in iOS Keychain (identity key, prekeys)
- Public keys uploaded to backend
- Session state managed per contact

**Message Flow:**
1. Sender fetches recipient's public keys from backend
2. Sender performs X3DH to establish shared secret
3. Sender encrypts message with Double Ratchet
4. Encrypted payload + sender's ratchet key sent to backend
5. Recipient fetches encrypted message
6. Recipient decrypts using their private key + sender's ratchet key

**Key Rotation:**
- Users can regenerate keys in MessagingSettingsView
- One-time prekeys consumed per message
- Ratchet advances with each message

---

## Push Notifications

**Configuration:**
- APNs Key: N2UGRH67CT (Token-based auth)
- Team ID: NV97R9Q8MF
- Bundle ID: com.prishajain.medaloffreedom
- Environment: Development/Sandbox (APNS_PRODUCTION=false)

**Format:**
```json
{
  "aps": {
    "alert": {
      "title": "MOF",
      "body": "Medal of Freedom"
    },
    "badge": 1,
    "sound": "default"
  },
  "type": "message",
  "message_id": 123,
  "from_user_id": 456,
  "from_username": "johndoe",
  "device_name": "Medal of Freedom",
  "encrypted": true
}
```

**Tested States:**
- ✅ Foreground (banner + in-app handling)
- ✅ Background (notification received)
- ✅ Killed (notification wakes app)

**Implementation:**
- Backend: `server/services/PushService.js` (node-apn)
- iOS: `PushNotificationService.swift` (UserNotifications framework)

---

## Testing Checklist

**Backend:**
- ✅ Auth: register, login, JWT validation
- ✅ Users: search, profile
- ✅ Contacts: add, list, remove
- ✅ Messages: send encrypted, history, read
- ✅ Push: register/unregister tokens, send notifications
- ✅ Encryption: key upload/fetch

**iOS:**
- ✅ Auth: register, login, logout, token persistence in Keychain
- ✅ Contacts: search, add, list, remove, selection persistence
- ✅ Messaging: BLE connection trigger, template substitution, encryption
- ✅ Location: GPS fetch, reverse geocoding, permission handling
- ✅ Push: permissions, receive (foreground/background/killed)
- ✅ Encryption: key generation, upload, encrypt/decrypt
- ⏳ Edge cases: offline queue, no internet, no contacts selected
- ⏳ BLE: Multiple device connections, background scanning

**Push Notification Test Results:**
See `PUSH_NOTIFICATION_TEST_RESULTS.md` for detailed test log.

---

## Server Details

**Production:** `142.93.184.210`
- SSH: `root@142.93.184.210`
- Directory: `/var/www/blescanner-backend/server`
- DB: PostgreSQL (user: `blescanner_user`, db: `blescanner`)
- Process: PM2 (`blescanner-backend`)
- Logs: `pm2 logs blescanner-backend`
- Restart: `pm2 restart blescanner-backend --update-env`

**APNs Configuration:**
- Key: N2UGRH67CT (created Nov 12, 2025)
- Previous key: X859SFN76P (REVOKED Nov 12, 2025 @ 3:40PM EST - compromised)
- Team: NV97R9Q8MF
- Bundle: com.prishajain.medaloffreedom
- Key file: `/var/www/blescanner-backend/server/config/AuthKey_N2UGRH67CT.p8`

**Environment Variables (.env):**
```bash
PORT=3000
DB_USER=blescanner_user
DB_HOST=localhost
DB_NAME=blescanner
DB_PASSWORD=<secure_password>
DB_PORT=5432
JWT_SECRET=<secure_secret>
APNS_KEY_ID=N2UGRH67CT
APNS_TEAM_ID=NV97R9Q8MF
APNS_TOPIC=com.prishajain.medaloffreedom
APNS_KEY_PATH=/var/www/blescanner-backend/server/config/AuthKey_N2UGRH67CT.p8
APNS_PRODUCTION=false
```

---

## Troubleshooting

**Backend:**
- Server down: `pm2 status`, `pm2 logs blescanner-backend`
- DB issues: `systemctl status postgresql`, check DB credentials
- Push not working: Check APNs key file exists, verify bundle ID matches app
- Encryption errors: Ensure encryption_keys table populated

**iOS:**
- JWT expired: Re-login (tokens last 30 days)
- Messages not sending: Check internet connection, contacts selected, auto-messaging enabled
- Push not received: Check permissions granted, device token registered on backend
- BLE not triggering: Verify messaging enabled in Settings → Messaging
- Location not showing: Check location permissions, wait for GPS lock
- Encryption failures: Regenerate keys in MessagingSettingsView
- Contact selections not persisting: Ensure ContactService.fetchContacts() called on launch

**Common Issues:**
- **BadDeviceToken (400)**: Delete and reinstall app to generate new token with current APNs key
- **DeviceTokenNotForTopic (400)**: Bundle ID mismatch between app and backend APNS_TOPIC
- **Location unavailable**: Permissions not granted or GPS unavailable
- **Decryption failed**: Recipient hasn't uploaded public keys or session state lost

---

## Recent Commits

**Commit 007edb1 (Nov 12, 2025) - "Major feature update"**
- Location tracking with reverse geocoding
- APNs key rotation (N2UGRH67CT)
- Message templates with line breaks and comprehensive info
- UI rebranding to Medal of Freedom
- Contact persistence fix
- Push notification format update
- Added {location} variable support
- 19 files changed, 572 insertions, 97 deletions

**Previous commits:**
- Updated encryption methods for iOS 17
- UI improvements and cleaner UX
- Initial encryption implementation

---

## Security & Privacy

**Backend:**
- ✅ bcrypt password hashing (≥10 rounds)
- ✅ JWT with strong secret, 30-day expiration
- ✅ Parameterized SQL queries (SQL injection prevention)
- ✅ End-to-end encryption (messages encrypted client-side)
- ⏳ TODO: Add HTTPS/SSL (Let's Encrypt)
- ⏳ TODO: Add rate limiting

**iOS:**
- ✅ JWT stored in Keychain (NOT UserDefaults)
- ✅ Encryption keys in Keychain
- ✅ Sensitive data not logged
- ⏳ Use HTTPS only (currently HTTP for dev)

**Privacy:**
- Minimal data collection (username, password hash, device tokens, encrypted messages)
- Username search only (no public user directory)
- Private contacts (not visible to other users)
- End-to-end encryption (backend cannot read messages)
- Location only sent when user triggers message (not continuous tracking)

**APNs Key Security:**
- .p8 files never committed to git (in .gitignore)
- Key files stored securely on production server
- Previous compromised key immediately revoked

---

## User Flow

**First-Time Setup:**
1. Download app → Register account → Login
2. Enable push notifications (prompted automatically)
3. Grant location permissions (prompted automatically)
4. Add emergency contacts (username search)
5. Select which contacts receive messages
6. Customize message template with personal info (replace ____)
7. Enable "Auto-Send Messages" toggle in Settings → Messaging

**Daily Use:**
1. Medal of Freedom BLE device comes in range
2. App detects connection (works in background)
3. If auto-messaging enabled:
   - Gets current location
   - Substitutes template variables
   - Encrypts message for each selected contact
   - Sends to backend
   - Backend sends push notifications
4. Recipients receive notification → Open app → View/decrypt message

**View Message History:**
1. Open Messages tab
2. See sent and received messages
3. Received messages auto-decrypt
4. Tap message for details

---

## Future Enhancements

**V1.1 (Post-Launch):**
- Group messaging (send to multiple contacts as group)
- Additional template variables (street address, custom fields)
- Read receipts
- Message retry on failure
- Offline queue for messages

**V1.2:**
- Voice messages (encrypted audio)
- Attachment support (documents, photos)
- Custom notification sounds per contact
- Multi-language support

**V2.0:**
- Device monitoring dashboard (battery, connection history)
- Analytics and insights
- Multi-device support (iPad, Watch)
- Emergency SOS button (manual trigger)
- Legal document storage (encrypted cloud backup)

---

## For New Developers / AI Assistants

**Getting Started:**
1. Clone repo: `git clone https://github.com/prishajain-23/BLEScanner.git`
2. Open `BLEScanner.xcodeproj` in Xcode
3. Backend is already deployed at 142.93.184.210
4. Build and run on device (not simulator - requires BLE)

**Key Files to Understand:**
- `BLEScannerApp.swift` - App entry point, auth flow
- `BLEManager.swift` - Bluetooth scanning and auto-messaging trigger
- `MessagingService.swift` - Core messaging logic
- `LocationService.swift` - GPS and reverse geocoding
- `CryptoEncryptionService.swift` - E2E encryption
- `MessagingSettingsView.swift` - Template management UI

**Testing:**
- Use two physical iOS devices (BLE doesn't work in simulator)
- Create two accounts on different devices
- Add each other as contacts
- Use BLE simulator device to trigger connections

**Common Tasks:**
- Add new template: Edit `MessagingSettingsView.swift` sample templates section
- Change location format: Modify `LocationService.swift` `formatLocation()`
- Update encryption: Modify `CryptoEncryptionService.swift`
- Add new API endpoint: Update `APIClient.swift` and create request/response models

**Architecture Notes:**
- SwiftUI with `@Observable` for state management
- Services are singletons (`shared`)
- Async/await for all async operations
- UserDefaults for app settings
- Keychain for sensitive data (JWT, keys)

---

**Last Updated:** Nov 12, 2025 | **License:** AGPLv3 | **Commit:** 007edb1
