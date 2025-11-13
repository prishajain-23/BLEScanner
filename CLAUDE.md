# BLEScanner Messaging System - Development Guide

## 🚀 CURRENT STATUS - November 6, 2025

**PHASE 1 COMPLETE ✅** - Backend deployed at `http://142.93.184.210`

**What's Complete:**
- ✅ PostgreSQL database (4 tables, 7 indexes)
- ✅ Node.js/Express API with JWT auth
- ✅ APNs push notifications configured (Key: N2UGRH67CT, Team: NV97R9Q8MF, Bundle: com.prishajain.medaloffreedom)
- ✅ Production deployment (PM2 + Nginx on 142.93.184.210)

**Next: Phase 2 - iOS Integration**

**iOS Tasks:**
1. **Day 4:** Auth layer (Models, APIClient, KeychainHelper, AuthService, LoginView)
2. **Day 5:** Messaging core (MessageService protocol, BLEScannerMessenger, BLE integration)
3. **Day 6:** UI (Contacts, MessageHistory, Settings)
4. **Day 7:** Push notifications (enable capability, NotificationService, test)

**API Config for iOS:**
```swift
struct APIConfig {
    static let baseURL = "http://142.93.184.210/api"
    static let timeout: TimeInterval = 30
}
```

---

## Quick Reference

**Goal:** Auto-send messages when Medal of Freedom connects via BLE

**Key Features:**
- Username/password auth
- Contact-based messaging (username search)
- Auto-trigger on BLE connection
- Push notifications
- Message history (last 50)

**Flow:** Medal of Freedom connects → BLEManager → POST /api/messages/send → Backend stores → APNs push → Recipient notified

**Stack:**
- Backend: Node.js + Express + PostgreSQL + JWT + bcrypt + node-apn
- iOS: Swift/SwiftUI + URLSession + Keychain + UserNotifications
- Deploy: DigitalOcean + PM2 + Nginx

---

## Database Schema

**Tables:** users, messages, message_recipients, contacts (4 tables, 7 indexes)

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
- POST `/messages/send` - {to_user_ids[], message, device_name}
- GET `/messages/history?limit=50` - Get history
- POST `/messages/:id/read` - Mark as read

**Devices:**
- POST `/devices/register-push` - {device_token, platform}
- DELETE `/devices/unregister-push`

All endpoints (except auth) require `Authorization: Bearer <token>` header.

---

## Implementation Timeline

### ✅ Phase 1: Backend (COMPLETE)
Backend deployed and running at 142.93.184.210

### 📍 Phase 2: iOS App (Days 4-7) - IN PROGRESS

**Day 4:** Auth (Models, APIClient, KeychainHelper, AuthService, Login/RegisterView)
**Day 5:** Messaging (MessageService protocol, BLEScannerMessenger, BLEManager integration)
**Day 6:** UI (Contact/Message views, Settings)
**Day 7:** Push notifications (capability, NotificationService, testing)

### Phase 3: Testing (Days 8-10)
**Day 8:** Integration testing
**Day 9:** Edge cases & error handling
**Day 10:** Polish & TestFlight prep

---

## User Flow

**First-Time Setup:**
1. Register/login → Enable notifications → Add contacts (username search) → Enable auto-messaging in Settings

**Daily Use:**
Medal of Freedom in range → Auto-connect → Message sent to contacts → Push notification → View history

---

## Code Structure

**Backend:** `server/` - config/, db/, middleware/, routes/, services/ (all implemented ✅)

**iOS to implement:**
- Models: User, Contact, Message
- Services: APIClient, AuthService, KeychainHelper, MessageService, BLEScannerMessenger, NotificationService
- Views: Auth/, Contacts/, Messages/, Settings/MessagingSettingsView
- Modify: BLEScannerApp.swift, BLEManager.swift, ContentView.swift

---

## Security & Privacy

**Backend:**
- bcrypt password hashing (≥10 rounds)
- JWT with strong secret, 30-day expiration
- Parameterized SQL queries
- TODO: Add HTTPS/SSL (Let's Encrypt)
- TODO: Add rate limiting

**iOS:**
- Store JWT in Keychain (NOT UserDefaults)
- Use HTTPS only
- Don't log sensitive data

**Privacy:**
- Minimal data collection (username, password hash, device tokens)
- Username search only (no user directory)
- Private contacts (not visible to others)

---

## Testing Checklist

**Backend (Phase 3):**
- Auth: register, login, JWT validation
- Users: search, profile
- Contacts: add, list, remove
- Messages: send, history, read
- Push: register/unregister tokens

**iOS (Phase 3):**
- Auth: register, login, logout, token persistence
- Contacts: search, add, list, remove
- Messaging: BLE connection trigger, foreground/background, history
- Push: permissions, receive (fg/bg/killed), tap to open
- Edge cases: offline queue, no internet, no contacts, empty states

---

## Server Details

**Production:** `142.93.184.210`
- SSH: `root@142.93.184.210`
- Directory: `/var/www/blescanner-backend/server`
- DB: PostgreSQL (user: `blescanner_user`, db: `blescanner`)
- Process: PM2 (`blescanner-backend`)
- APNs: Key N2UGRH67CT, Team NV97R9Q8MF, Bundle com.prishajain.medaloffreedom

---

## Troubleshooting

**Backend:**
- Server down: `pm2 status`, `pm2 logs`
- DB issues: `systemctl status postgresql`
- Push not working: Check APNs config, device tokens

**iOS:**
- JWT expired: Re-login
- Messages not sending: Check internet, contacts configured
- Push not received: Check permissions, device token registered
- BLE not triggering: Verify messaging enabled in Settings

---

## Future Enhancements

**V1.1:** Group messaging, custom templates, read receipts
**V1.2:** E2E encryption, voice messages, location sharing
**V2.0:** Attachments, device monitoring, analytics, multi-device

---

**Last Updated:** Nov 6, 2025 | **License:** AGPLv3
