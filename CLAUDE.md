# BLEScanner Messaging System - Development Guide

This document contains the complete architecture and implementation plan for adding peer-to-peer messaging to BLEScanner.

---

## 🚀 PROGRESS LOG - Session November 4-5, 2025

### ✅ COMPLETED: Phase 1 - Backend API (Days 1-3)

**Day 1: Server & Database Setup** ✅
- PostgreSQL 15 installed and configured
- Database schema created (4 tables: users, messages, message_recipients, contacts)
- 7 performance indexes implemented
- Node.js + Express project structure
- Environment variables configured
- Database connection tested and working

**Day 2: API Endpoints** ✅
- Authentication routes (register, login) - **TESTED**
- User routes (search, profile) - **TESTED**
- Contact routes (add, list, remove) - **TESTED**
- Message routes (send, history, mark as read) - **TESTED**
- Device routes (push token registration) - **READY**
- JWT authentication middleware
- bcrypt password hashing (10 rounds)
- Error handling middleware
- All endpoints tested with curl

**Day 3: Push Notifications** ✅
- APNs authentication key configured (Key ID: X859SFN76P)
- Team ID: NV97R9Q8MF
- Bundle ID: com.prishajain.blescanner
- PushService implemented with node-apn
- Message sending triggers push notifications
- APNs provider initialized successfully
- Development environment (sandbox) configured

**Backend Status:** 🟢 100% COMPLETE and TESTED
- Running on: http://localhost:3000
- Database: PostgreSQL with 2 test users (alice, bob)
- All API endpoints functional
- Push notifications configured and ready

---

### 🔄 IN PROGRESS: Phase 2 - iOS App Integration (Day 4)

**Completed Today:**
- ✅ API networking layer (APIClient.swift)
- ✅ Data models (MessagingModels.swift)
- ✅ Keychain secure storage (KeychainHelper.swift)
- ✅ Authentication service (AuthService.swift)
- ✅ Login/Register UI (AuthView.swift)
- ✅ App authentication flow (BLEScannerApp.swift updated)
- ✅ Swift 5.9+ `@Observable` patterns implemented

**Current Issue: iOS Networking Configuration** ⚠️
- **Problem:** iOS app cannot connect to `localhost:3000` from physical device
- **Error:** "Connection refused" (Error Code -1004)
- **Root Cause:** Physical iOS devices cannot access Mac's localhost via loopback address
- **Status:** Identified, solution documented below

---

### 📋 NEXT SESSION - Immediate Tasks

**Priority 1: Fix Networking** (15 minutes)
1. Update backend to listen on `0.0.0.0` instead of localhost
2. Find Mac's IP address (System Settings → Network)
3. Create environment-based configuration for iOS app
4. Update APIConstants.swift with Mac's IP for physical device testing
5. Configure macOS firewall to allow port 3000

**Priority 2: Test Authentication** (30 minutes)
1. Build and run on iOS simulator (should work with localhost)
2. Build and run on physical device (with Mac IP)
3. Test registration flow
4. Test login flow
5. Verify token storage in Keychain

**Priority 3: Add Messaging Features** (2-3 hours)
1. Create MessagingService.swift
2. Create ContactListView.swift
3. Create MessageHistoryView.swift
4. Integrate with BLEManager for auto-send
5. Add NotificationService for push handling

**Priority 4: End-to-End Testing** (1 hour)
1. Register device for push notifications
2. Send test message
3. Verify push notification received
4. Test BLE connection → auto-message flow

---

### 🛠️ iOS DEVELOPMENT - NETWORKING CONFIGURATION

#### The Problem

**Current Configuration:**
```swift
// APIConstants.swift
static let baseURL = "http://localhost:3000/api"
```

**Why It Fails:**
- iOS Simulator: ✅ Can access `localhost` (shares Mac's network)
- Physical Device: ❌ Cannot access `localhost` (different network entity)
- Error: `nw_socket_handle_socket_event Socket SO_ERROR [61: Connection refused]`

#### Solution: Environment-Based Configuration

**Step 1: Find Your Mac's IP Address**
```bash
# Terminal command
ifconfig | grep "inet " | grep -v 127.0.0.1

# Or: System Settings → Network → Wi-Fi/Ethernet → IP Address
# Example: 192.168.1.45
```

**Step 2: Update Backend (server/index.js)**
```javascript
// Change from:
app.listen(PORT, () => {

// To:
app.listen(PORT, '0.0.0.0', () => {  // Listen on all network interfaces
  console.log(`Server accessible at: http://YOUR_MAC_IP:${PORT}`);
});
```

**Step 3: Create EnvironmentConfig.swift**
```swift
import Foundation

struct EnvironmentConfig {
    static let isSimulator = TARGET_OS_SIMULATOR != 0

    static let baseURL: String = {
        if isSimulator {
            return "http://localhost:3000/api"
        } else {
            // UPDATE THIS with your Mac's actual IP address
            return "http://192.168.1.45:3000/api"
        }
    }()
}
```

**Step 4: Update APIConstants.swift**
```swift
struct APIConfig {
    static let baseURL = EnvironmentConfig.baseURL  // Use environment-based URL
    static let timeout: TimeInterval = 30
}
```

**Step 5: Configure macOS Firewall**
- System Settings → Privacy & Security → Firewall
- Either: Allow Terminal/Node.js incoming connections
- Or: Temporarily disable firewall for development

**Step 6: Verify Network Access**
```bash
# Test from Mac terminal
curl http://YOUR_MAC_IP:3000/health

# Test from iPhone Safari
http://YOUR_MAC_IP:3000/health

# Expected response:
# {"status":"ok","timestamp":"...","environment":"development"}
```

#### Testing Checklist

Before each iOS testing session:

- [ ] Mac and iPhone on **same Wi-Fi network**
- [ ] Backend server running: `cd server && npm start`
- [ ] Server listening on `0.0.0.0` (not just localhost)
- [ ] macOS firewall allows port 3000
- [ ] iOS app has correct IP in EnvironmentConfig.swift
- [ ] Test `/health` endpoint from iPhone Safari first

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Implementation Timeline](#implementation-timeline)
7. [User Flow](#user-flow)
8. [Code Structure](#code-structure)
9. [Security Considerations](#security-considerations)
10. [Testing Checklist](#testing-checklist)

---

## Project Overview

### Goal
Enable BLEScanner users to automatically send messages to other BLEScanner users when their ESP32 device connects via Bluetooth.

### Key Requirements
- ✅ Both sender and recipient must have BLEScanner installed
- ✅ Messages triggered automatically by BLE connection events
- ✅ Works in background (when app is backgrounded)
- ✅ Username-based user discovery
- ✅ Push notifications for real-time delivery
- ✅ Basic message history (last 50 messages)
- ✅ Privacy-focused (users control who they message)

### Design Decisions
- **Auth**: Username + password (simple, fast to implement)
- **Discovery**: Username search (@username style)
- **Backend**: Node.js + Express + PostgreSQL
- **Messaging**: Server-mediated (not P2P)
- **History**: Basic (last 50 messages, simple list)
- **Timeline**: 7-10 days

---

## Architecture

### High-Level Flow

```
User A (Sender)                    Your Server                User B (Recipient)
---------------                    -----------                ------------------
ESP32 connects
    ↓
BLEManager detects
    ↓
POST /api/messages/send
{                                → Store message
  from_user_id,                  → Look up recipients
  to_user_ids: [B],              → Queue for delivery
  message: "Device connected",
  device_name: "ESP32"
}                                     ↓
                                  Send APNs push
                                      ↓
                                                          ← Push notification arrives
                                                            "sarah: ESP32 connected"
                                                          ← User taps notification
                                                          ← App opens, shows details
```

### Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  BLEScanner iOS App                      │
├─────────────────────────────────────────────────────────┤
│  UI Layer                                               │
│  - LoginView / RegisterView                             │
│  - ContactSearchView / ContactListView                  │
│  - MessageHistoryView                                   │
│  - Settings (Messaging Config)                          │
├─────────────────────────────────────────────────────────┤
│  Service Layer                                          │
│  - AuthService (login, register, token mgmt)            │
│  - MessageService (protocol/abstraction)                │
│  - BLEScannerMessenger (HTTP client impl)               │
│  - NotificationService (APNs handling)                  │
├─────────────────────────────────────────────────────────┤
│  Core Layer                                             │
│  - BLEManager (existing - integrate messaging)          │
│  - Models (User, Message, Contact)                      │
└─────────────────────────────────────────────────────────┘
                            ↕ HTTPS
┌─────────────────────────────────────────────────────────┐
│              DigitalOcean Server (Ubuntu)                │
├─────────────────────────────────────────────────────────┤
│  Node.js + Express API                                  │
│  - Auth routes (/api/auth/*)                            │
│  - User routes (/api/users/*)                           │
│  - Contact routes (/api/contacts/*)                     │
│  - Message routes (/api/messages/*)                     │
│  - Device routes (/api/devices/*)                       │
├─────────────────────────────────────────────────────────┤
│  Services                                               │
│  - AuthService (JWT generation/validation)              │
│  - MessageService (send, store, retrieve)               │
│  - PushService (APNs integration)                       │
├─────────────────────────────────────────────────────────┤
│  PostgreSQL Database                                    │
│  - users, messages, message_recipients, contacts        │
└─────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────┐
│         Apple Push Notification Service (APNs)          │
└─────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Backend
- **Runtime**: Node.js 18+ LTS
- **Framework**: Express.js 4.x
- **Database**: PostgreSQL 15+
- **ORM**: pg (node-postgres) or Sequelize
- **Auth**: JWT (jsonwebtoken package)
- **Password Hashing**: bcrypt
- **Push Notifications**: node-apn or apns2
- **Process Manager**: PM2
- **Server**: DigitalOcean Droplet (Ubuntu 22.04)

### iOS App
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 16.0+
- **Architecture**: Observable + MVVM
- **Networking**: URLSession (native)
- **Storage**: Keychain (credentials), UserDefaults (settings)
- **Push**: UserNotifications framework

### DevOps
- **Hosting**: DigitalOcean ($6-12/month droplet)
- **SSL**: Let's Encrypt (free, via Certbot)
- **Domain**: Optional custom domain
- **Monitoring**: PM2 built-in monitoring
- **Backup**: PostgreSQL daily backups

---

## Database Schema

### SQL Schema

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    device_token VARCHAR(255),  -- APNs device token
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Messages table
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    from_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    device_name VARCHAR(100),  -- ESP32 device name (e.g., "Living Room Sensor")
    created_at TIMESTAMP DEFAULT NOW()
);

-- Message recipients (many-to-many relationship)
CREATE TABLE message_recipients (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
    to_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    delivered BOOLEAN DEFAULT FALSE,
    delivered_at TIMESTAMP,
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    UNIQUE(message_id, to_user_id)
);

-- Contacts (who can message whom)
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    nickname VARCHAR(100),  -- Optional friendly name
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, contact_user_id),
    CHECK(user_id != contact_user_id)  -- Can't add yourself
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_messages_from ON messages(from_user_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_recipients_user ON message_recipients(to_user_id);
CREATE INDEX idx_recipients_message ON message_recipients(message_id);
CREATE INDEX idx_contacts_user ON contacts(user_id);
CREATE INDEX idx_contacts_search ON contacts(contact_user_id);
```

### Entity Relationships

```
users (1) ──< (many) messages
users (1) ──< (many) message_recipients
users (1) ──< (many) contacts

messages (1) ──< (many) message_recipients
```

---

## API Endpoints

### Base URL
```
Production: https://your-domain.com/api
Development: http://localhost:3000/api
```

### Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "sarah",
  "password": "securepassword123"
}

Response 201:
{
  "success": true,
  "user": {
    "id": 1,
    "username": "sarah",
    "created_at": "2025-11-04T14:30:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Response 400:
{
  "success": false,
  "error": "Username already exists"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "sarah",
  "password": "securepassword123"
}

Response 200:
{
  "success": true,
  "user": {
    "id": 1,
    "username": "sarah"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Response 401:
{
  "success": false,
  "error": "Invalid credentials"
}
```

---

### User Endpoints

#### Search Users
```http
GET /api/users/search?q=sara
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "users": [
    {
      "id": 1,
      "username": "sarah"
    },
    {
      "id": 5,
      "username": "sarahconnor"
    }
  ]
}
```

#### Get My Profile
```http
GET /api/users/me
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "user": {
    "id": 1,
    "username": "sarah",
    "created_at": "2025-11-04T14:30:00Z",
    "contact_count": 5
  }
}
```

---

### Contact Endpoints

#### Add Contact
```http
POST /api/contacts/add
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "contact_username": "john"
}

Response 201:
{
  "success": true,
  "contact": {
    "id": 15,
    "username": "john",
    "added_at": "2025-11-04T15:00:00Z"
  }
}

Response 404:
{
  "success": false,
  "error": "User not found"
}
```

#### List My Contacts
```http
GET /api/contacts
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "contacts": [
    {
      "id": 2,
      "username": "john",
      "nickname": null,
      "added_at": "2025-11-04T15:00:00Z"
    },
    {
      "id": 3,
      "username": "emma",
      "nickname": "Emma (Sister)",
      "added_at": "2025-11-03T10:20:00Z"
    }
  ]
}
```

#### Remove Contact
```http
DELETE /api/contacts/:contactId
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "message": "Contact removed"
}
```

---

### Message Endpoints

#### Send Message
```http
POST /api/messages/send
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "to_user_ids": [2, 3],
  "message": "Living Room Sensor connected",
  "device_name": "Living Room Sensor"
}

Response 201:
{
  "success": true,
  "message": {
    "id": 42,
    "from_user_id": 1,
    "message_text": "Living Room Sensor connected",
    "device_name": "Living Room Sensor",
    "created_at": "2025-11-04T16:45:22Z",
    "recipients": [2, 3]
  },
  "push_sent": true
}

Response 400:
{
  "success": false,
  "error": "No recipients specified"
}
```

#### Get Message History
```http
GET /api/messages/history?limit=50&offset=0
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "messages": [
    {
      "id": 42,
      "from_username": "sarah",
      "from_user_id": 1,
      "message_text": "Living Room Sensor connected",
      "device_name": "Living Room Sensor",
      "created_at": "2025-11-04T16:45:22Z",
      "is_sent": true
    },
    {
      "id": 38,
      "from_username": "john",
      "from_user_id": 2,
      "message_text": "Garage Door Sensor connected",
      "device_name": "Garage Door",
      "created_at": "2025-11-04T14:20:15Z",
      "is_sent": false
    }
  ],
  "total": 127,
  "limit": 50,
  "offset": 0
}
```

#### Mark Message as Read
```http
POST /api/messages/:messageId/read
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "message": "Message marked as read"
}
```

---

### Device Endpoints

#### Register Push Token
```http
POST /api/devices/register-push
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_token": "abc123def456...",
  "platform": "ios"
}

Response 200:
{
  "success": true,
  "message": "Device token registered"
}
```

#### Unregister Push Token
```http
DELETE /api/devices/unregister-push
Authorization: Bearer <jwt_token>

Response 200:
{
  "success": true,
  "message": "Device token removed"
}
```

---

## Implementation Timeline

### Phase 1: Backend Setup (Days 1-3)

#### Day 1: Server & Database
- [ ] Create DigitalOcean droplet (Ubuntu 22.04)
- [ ] Install Node.js, PostgreSQL, Nginx, Certbot
- [ ] Configure firewall (UFW)
- [ ] Set up SSL certificate with Let's Encrypt
- [ ] Create PostgreSQL database and user
- [ ] Run schema SQL to create tables
- [ ] Install PM2 globally
- [ ] Test database connection

**Files to create:**
- `server/package.json`
- `server/config/database.js`
- `server/db/schema.sql`
- `server/.env` (DB credentials, JWT secret)

#### Day 2: API Endpoints
- [ ] Set up Express.js project structure
- [ ] Implement auth middleware (JWT validation)
- [ ] Create auth routes (register, login)
- [ ] Create user routes (search, profile)
- [ ] Create contact routes (add, list, remove)
- [ ] Create message routes (send, history, mark read)
- [ ] Create device routes (register push token)
- [ ] Add error handling middleware
- [ ] Test all endpoints with Postman/curl

**Files to create:**
- `server/index.js`
- `server/middleware/auth.js`
- `server/routes/auth.js`
- `server/routes/users.js`
- `server/routes/contacts.js`
- `server/routes/messages.js`
- `server/routes/devices.js`
- `server/services/AuthService.js`
- `server/services/MessageService.js`

#### Day 3: Push Notifications
- [ ] Get APNs auth key from Apple Developer portal
- [ ] Configure APNs in backend
- [ ] Implement push notification sending
- [ ] Test push notifications with test device token
- [ ] Add push sending to message creation flow
- [ ] Handle push errors gracefully
- [ ] Deploy backend with PM2

**Files to create:**
- `server/services/PushService.js`
- `server/config/apns.js`
- `server/ecosystem.config.js` (PM2 config)

---

### Phase 2: iOS App (Days 4-7)

#### Day 4: User Authentication
- [ ] Create `Models/User.swift`
- [ ] Create `Services/AuthService.swift`
- [ ] Create `Services/KeychainHelper.swift`
- [ ] Create `Views/Auth/LoginView.swift`
- [ ] Create `Views/Auth/RegisterView.swift`
- [ ] Update `BLEScannerApp.swift` to show login on first launch
- [ ] Store JWT token in Keychain
- [ ] Add logout functionality
- [ ] Test registration and login flows

**Files to create:**
- `BLEScanner/Models/User.swift`
- `BLEScanner/Models/Contact.swift`
- `BLEScanner/Models/Message.swift`
- `BLEScanner/Services/AuthService.swift`
- `BLEScanner/Services/KeychainHelper.swift`
- `BLEScanner/Views/Auth/LoginView.swift`
- `BLEScanner/Views/Auth/RegisterView.swift`

#### Day 5: Messaging Core
- [ ] Create `Services/MessageService.swift` (protocol)
- [ ] Create `Services/BLEScannerMessenger.swift` (implementation)
- [ ] Create `Services/APIClient.swift` (HTTP client)
- [ ] Integrate `MessageService` into `BLEManager`
- [ ] Add message sending on ESP32 connection
- [ ] Add message queueing for offline scenarios
- [ ] Test message sending in foreground
- [ ] Test message sending in background

**Files to create:**
- `BLEScanner/Services/MessageService.swift`
- `BLEScanner/Services/BLEScannerMessenger.swift`
- `BLEScanner/Services/APIClient.swift`
- `BLEScanner/Services/MessageQueue.swift`

**Files to modify:**
- `BLEScanner/BLEManager.swift` (add MessageService dependency)

#### Day 6: Contacts & Settings UI
- [ ] Create `Views/Contacts/ContactSearchView.swift`
- [ ] Create `Views/Contacts/ContactListView.swift`
- [ ] Create `Views/Contacts/AddContactSheet.swift`
- [ ] Create `Views/Messages/MessageHistoryView.swift`
- [ ] Add "Messaging" section to Settings
- [ ] Add enable/disable messaging toggle
- [ ] Add custom message template field
- [ ] Add "Manage Contacts" button
- [ ] Add "View Message History" button
- [ ] Test contact search and adding

**Files to create:**
- `BLEScanner/Views/Contacts/ContactSearchView.swift`
- `BLEScanner/Views/Contacts/ContactListView.swift`
- `BLEScanner/Views/Contacts/AddContactSheet.swift`
- `BLEScanner/Views/Messages/MessageHistoryView.swift`
- `BLEScanner/Views/Settings/MessagingSettingsView.swift`

**Files to modify:**
- `BLEScanner/ContentView.swift` (add navigation to contacts/messages)

#### Day 7: Push Notifications
- [ ] Enable Push Notifications capability in Xcode
- [ ] Request notification permissions on first launch
- [ ] Create `Services/NotificationService.swift`
- [ ] Handle notification authorization
- [ ] Register device token with backend
- [ ] Handle push notification payloads
- [ ] Show in-app notification banner
- [ ] Handle notification tap (open message history)
- [ ] Test push notifications in foreground
- [ ] Test push notifications in background

**Files to create:**
- `BLEScanner/Services/NotificationService.swift`
- `BLEScanner/Views/Notifications/NotificationBannerView.swift`

**Files to modify:**
- `BLEScanner/BLEScannerApp.swift` (register for notifications)

---

### Phase 3: Testing & Polish (Days 8-10)

#### Day 8: Integration Testing
- [ ] Test full user registration → login flow
- [ ] Test username search functionality
- [ ] Test adding contacts
- [ ] Test BLE connection → message sent → push received
- [ ] Test message history display
- [ ] Test with multiple users (2+ test accounts)
- [ ] Test background BLE connection
- [ ] Test offline message queueing

#### Day 9: Edge Cases & Error Handling
- [ ] Handle network errors gracefully
- [ ] Show user-friendly error messages
- [ ] Handle invalid username search (no results)
- [ ] Handle no contacts configured (helpful prompt)
- [ ] Handle message send failures (retry logic)
- [ ] Handle expired JWT tokens (re-login)
- [ ] Handle duplicate contact adds
- [ ] Test with airplane mode on/off

#### Day 10: Final Polish
- [ ] Update onboarding flow with messaging setup
- [ ] Add helpful tooltips/instructions
- [ ] Test full flow from fresh install
- [ ] Update app description and screenshots
- [ ] Write README with setup instructions
- [ ] Update LICENSE to AGPLv3
- [ ] Create PRIVACY_POLICY.md
- [ ] Prepare for TestFlight/App Store submission

---

## User Flow

### First-Time User Experience

```
1. User downloads BLEScanner from App Store
2. Opens app → sees login/register screen
3. Taps "Register" → enters username & password
4. Account created → logs in automatically
5. Sees main BLE scanner interface
6. Prompted to enable notifications → taps "Allow"
7. Device token registered with backend
8. Goes to Settings → Messaging
9. Taps "Add Contacts"
10. Searches for friend's username
11. Adds friend as contact
12. Enables "Send messages on connection"
13. Pairs with ESP32 device
14. ESP32 connects → message sent automatically
15. Friend receives push notification
16. Friend opens BLEScanner → sees message in history
```

### Daily Usage Flow

```
User has ESP32 in their bag/car/device
    ↓
BLEScanner running in background with auto-connect enabled
    ↓
ESP32 comes in range (or powers on)
    ↓
BLE auto-connect triggers (existing functionality)
    ↓
BLEManager calls MessageService.sendConnectionMessage()
    ↓
Message sent to backend API (with retry if offline)
    ↓
Backend pushes to all recipient device tokens
    ↓
Recipients get notification: "sarah: Living Room Sensor connected"
    ↓
Recipient taps notification → opens BLEScanner
    ↓
Shows message history with timestamp and device info
```

---

## Code Structure

### Backend Structure

```
server/
├── config/
│   ├── database.js          # PostgreSQL connection config
│   ├── apns.js              # APNs configuration
│   └── jwt.js               # JWT secret and options
├── db/
│   ├── schema.sql           # Database schema
│   └── migrations/          # Future schema changes
├── middleware/
│   ├── auth.js              # JWT authentication middleware
│   ├── errorHandler.js      # Global error handler
│   └── rateLimiter.js       # Rate limiting (optional)
├── routes/
│   ├── auth.js              # /api/auth/* routes
│   ├── users.js             # /api/users/* routes
│   ├── contacts.js          # /api/contacts/* routes
│   ├── messages.js          # /api/messages/* routes
│   └── devices.js           # /api/devices/* routes
├── services/
│   ├── AuthService.js       # Auth logic (JWT, password hashing)
│   ├── MessageService.js    # Message CRUD operations
│   ├── PushService.js       # APNs push notification sending
│   └── DatabaseService.js   # Database query helpers
├── utils/
│   ├── logger.js            # Winston logging
│   └── validator.js         # Input validation helpers
├── .env                     # Environment variables (not in git)
├── .gitignore
├── package.json
├── ecosystem.config.js      # PM2 configuration
└── index.js                 # Express app entry point
```

### iOS Structure

```
BLEScanner/
├── App/
│   └── BLEScannerApp.swift  # App entry point (MODIFIED)
├── Models/
│   ├── User.swift           # User model (NEW)
│   ├── Contact.swift        # Contact model (NEW)
│   ├── Message.swift        # Message model (NEW)
│   ├── BLEDevice.swift      # Existing BLE models
│   └── Models.swift         # Existing (keep as-is)
├── Services/
│   ├── AuthService.swift           # Auth & token management (NEW)
│   ├── MessageService.swift        # Protocol/abstraction (NEW)
│   ├── BLEScannerMessenger.swift   # HTTP implementation (NEW)
│   ├── APIClient.swift             # HTTP client utility (NEW)
│   ├── NotificationService.swift   # Push notification handling (NEW)
│   ├── MessageQueue.swift          # Offline queueing (NEW)
│   ├── KeychainHelper.swift        # Keychain wrapper (NEW)
│   ├── BLEManager.swift            # Existing (MODIFIED)
│   ├── NotificationManager.swift   # Existing (keep as-is)
│   └── ShortcutManager.swift       # Existing (keep as-is)
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift         # Login screen (NEW)
│   │   └── RegisterView.swift      # Register screen (NEW)
│   ├── Contacts/
│   │   ├── ContactListView.swift   # List of contacts (NEW)
│   │   ├── ContactSearchView.swift # Search users (NEW)
│   │   └── AddContactSheet.swift   # Add contact modal (NEW)
│   ├── Messages/
│   │   ├── MessageHistoryView.swift    # Message list (NEW)
│   │   └── MessageDetailView.swift     # Message details (NEW)
│   ├── Settings/
│   │   └── MessagingSettingsView.swift # Messaging config (NEW)
│   ├── Notifications/
│   │   └── NotificationBannerView.swift # In-app banner (NEW)
│   ├── ContentView.swift           # Existing (MODIFIED - add nav)
│   └── AutomationGuideView.swift   # Existing (keep as-is)
├── Utilities/
│   ├── Constants.swift        # API URLs, config (NEW)
│   └── Extensions.swift       # Helper extensions (NEW)
├── Resources/
│   ├── Assets.xcassets
│   └── Info.plist            # (MODIFIED - add push capability)
└── BLEScanner.entitlements   # (MODIFIED - add push)
```

---

## Security Considerations

### Backend Security

1. **Password Security**
   - Use bcrypt with salt rounds ≥ 10
   - Never log passwords
   - Minimum password length: 8 characters
   - Consider adding password strength requirements

2. **JWT Tokens**
   - Use strong secret (256-bit random)
   - Set expiration (e.g., 30 days)
   - Include user ID in payload
   - Sign with HS256 or RS256

3. **API Rate Limiting**
   - Limit login attempts: 5/hour per IP
   - Limit message sending: 100/hour per user
   - Limit registration: 3/hour per IP

4. **Input Validation**
   - Sanitize all user inputs
   - Validate username format (alphanumeric + underscore)
   - Limit message length (e.g., 500 chars)
   - SQL injection prevention (use parameterized queries)

5. **HTTPS Only**
   - Enforce SSL/TLS
   - Redirect HTTP → HTTPS
   - Use Let's Encrypt for free SSL

### iOS Security

1. **Token Storage**
   - Store JWT in Keychain (NOT UserDefaults)
   - Use `kSecAttrAccessibleWhenUnlocked`
   - Delete token on logout

2. **Network Security**
   - Use HTTPS only
   - Implement certificate pinning (optional, advanced)
   - Handle network errors without exposing internals

3. **User Data**
   - Don't log sensitive data
   - Clear message cache on logout (optional)
   - Respect user privacy settings

### Privacy Considerations

1. **Data Collection**
   - Only collect: username, password hash, device tokens
   - Don't collect: email, phone, real names (unless user adds)
   - Be transparent in privacy policy

2. **Message Storage**
   - Store messages encrypted at rest (PostgreSQL encryption)
   - Consider message auto-deletion after 30 days
   - Allow users to delete their message history

3. **Contact Visibility**
   - Users can only search existing usernames (no directory)
   - Can't enumerate users
   - Contacts are private (not visible to others)

4. **Device Tokens**
   - Only store latest device token per user
   - Delete token on logout
   - Handle token expiration gracefully

---

## Testing Checklist

### Backend Tests

**Authentication**
- [ ] Register with valid username/password
- [ ] Register with existing username (should fail)
- [ ] Register with invalid username format (should fail)
- [ ] Login with correct credentials
- [ ] Login with wrong password (should fail)
- [ ] Access protected route with valid JWT
- [ ] Access protected route with invalid JWT (should fail)
- [ ] Access protected route with expired JWT (should fail)

**Users**
- [ ] Search for existing username
- [ ] Search for partial username match
- [ ] Search for non-existent username (empty results)
- [ ] Get own profile

**Contacts**
- [ ] Add contact by username
- [ ] Add non-existent user (should fail)
- [ ] Add duplicate contact (should fail gracefully)
- [ ] List contacts
- [ ] Remove contact

**Messages**
- [ ] Send message to one recipient
- [ ] Send message to multiple recipients
- [ ] Send message with no recipients (should fail)
- [ ] Get message history
- [ ] Get message history with pagination
- [ ] Mark message as read

**Push Notifications**
- [ ] Register device token
- [ ] Update device token
- [ ] Unregister device token
- [ ] Send push on new message
- [ ] Handle invalid device tokens

### iOS Tests

**Authentication**
- [ ] Register new user
- [ ] Login existing user
- [ ] Logout (clears Keychain)
- [ ] Token persists across app restarts
- [ ] Re-login on expired token

**Contacts**
- [ ] Search for users
- [ ] Add contact
- [ ] View contact list
- [ ] Remove contact
- [ ] Empty state when no contacts

**Messaging**
- [ ] Send message on BLE connection (foreground)
- [ ] Send message on BLE connection (background)
- [ ] Message appears in history
- [ ] Receive push notification
- [ ] Tap notification opens app
- [ ] Offline queue works (send when back online)

**BLE Integration**
- [ ] Auto-connect still works
- [ ] Connection triggers message send
- [ ] Multiple connections send multiple messages
- [ ] Disconnection doesn't send message (only connections)
- [ ] Works with messaging disabled

**Push Notifications**
- [ ] Request permission on first launch
- [ ] Device token registered with backend
- [ ] Receive notification while app in foreground
- [ ] Receive notification while app in background
- [ ] Receive notification while app killed
- [ ] Notification shows correct message and sender

**Edge Cases**
- [ ] No internet (message queued)
- [ ] Airplane mode (message queued)
- [ ] Backend down (shows error)
- [ ] No contacts configured (helpful message)
- [ ] Empty message history (empty state)
- [ ] Long usernames (truncated properly)
- [ ] Long messages (truncated or wrap)

---

## Environment Variables

### Backend `.env` file

```bash
# Server
NODE_ENV=production
PORT=3000
API_BASE_URL=https://your-domain.com

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=blescanner
DB_USER=blescanner_user
DB_PASSWORD=your_secure_password_here

# JWT
JWT_SECRET=your_256_bit_secret_key_here_use_crypto.randomBytes(32)
JWT_EXPIRATION=30d

# APNs
APNS_KEY_ID=ABC123XYZ
APNS_TEAM_ID=TEAM123456
APNS_TOPIC=com.yourcompany.BLEScanner
APNS_KEY_PATH=/path/to/AuthKey_ABC123XYZ.p8
APNS_PRODUCTION=true

# Logging
LOG_LEVEL=info
```

### iOS Constants

```swift
// BLEScanner/Utilities/Constants.swift

struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:3000/api"
    #else
    static let baseURL = "https://your-domain.com/api"
    #endif

    static let timeout: TimeInterval = 30
}

struct AppConfig {
    static let messageHistoryLimit = 50
    static let maxRetryAttempts = 3
    static let offlineQueueLimit = 100
}
```

---

## Deployment

### Backend Deployment (DigitalOcean)

1. **Create Droplet**
   ```bash
   # Ubuntu 22.04, $6/month Basic plan, nearest datacenter
   ```

2. **Initial Server Setup**
   ```bash
   # SSH into server
   ssh root@your_server_ip

   # Update packages
   apt update && apt upgrade -y

   # Install Node.js 18
   curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
   apt install -y nodejs

   # Install PostgreSQL
   apt install -y postgresql postgresql-contrib

   # Install Nginx
   apt install -y nginx

   # Install Certbot for SSL
   apt install -y certbot python3-certbot-nginx

   # Install PM2
   npm install -g pm2
   ```

3. **Configure PostgreSQL**
   ```bash
   # Switch to postgres user
   sudo -u postgres psql

   # Create database and user
   CREATE DATABASE blescanner;
   CREATE USER blescanner_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE blescanner TO blescanner_user;
   \q
   ```

4. **Deploy Code**
   ```bash
   # Clone your repo
   cd /var/www
   git clone https://github.com/yourusername/BLEScanner-Backend.git
   cd BLEScanner-Backend

   # Install dependencies
   npm install --production

   # Set up environment variables
   nano .env  # Paste your production .env

   # Run database schema
   psql -U blescanner_user -d blescanner -f db/schema.sql

   # Start with PM2
   pm2 start ecosystem.config.js
   pm2 save
   pm2 startup
   ```

5. **Configure Nginx**
   ```bash
   nano /etc/nginx/sites-available/blescanner
   ```

   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

   ```bash
   ln -s /etc/nginx/sites-available/blescanner /etc/nginx/sites-enabled/
   nginx -t
   systemctl reload nginx
   ```

6. **Set Up SSL**
   ```bash
   certbot --nginx -d your-domain.com
   # Follow prompts, choose redirect HTTP to HTTPS
   ```

7. **Set Up Firewall**
   ```bash
   ufw allow OpenSSH
   ufw allow 'Nginx Full'
   ufw enable
   ```

### iOS App Deployment

1. **Configure Signing**
   - Xcode → Targets → BLEScanner → Signing & Capabilities
   - Select your Team
   - Update Bundle Identifier

2. **Enable Push Notifications**
   - Signing & Capabilities → + Capability → Push Notifications
   - Enable "Remote notifications" background mode

3. **Get APNs Key**
   - Apple Developer → Certificates, IDs & Profiles → Keys
   - Create new key with "Apple Push Notifications service (APNs)"
   - Download .p8 file
   - Note Key ID and Team ID

4. **TestFlight**
   - Archive app (Product → Archive)
   - Distribute → App Store Connect
   - Upload to TestFlight
   - Add internal/external testers

5. **App Store**
   - Prepare screenshots and description
   - Submit for review
   - Include privacy policy URL
   - Explain AGPLv3 license if asked

---

## Troubleshooting

### Common Backend Issues

**"Connection refused" from iOS**
- Check server is running: `pm2 status`
- Check firewall: `ufw status`
- Check Nginx config: `nginx -t`
- Check server IP/domain in iOS app

**"Database connection failed"**
- Check PostgreSQL is running: `systemctl status postgresql`
- Verify DB credentials in `.env`
- Check database exists: `psql -U postgres -l`

**"Push notifications not working"**
- Verify APNs key path is correct
- Check Key ID and Team ID match
- Ensure bundle ID matches APNs topic
- Check device token is being saved
- Look for APNs errors in logs: `pm2 logs`

### Common iOS Issues

**"Invalid JWT token"**
- Token may be expired (check backend JWT_EXPIRATION)
- Keychain may be corrupted (delete and re-login)
- Backend JWT_SECRET may have changed

**"Messages not sending"**
- Check internet connection
- Verify user has contacts added
- Check message queue isn't full
- Look for errors in Xcode console

**"Push notifications not received"**
- Check notification permissions: Settings → BLEScanner → Notifications
- Device token may not be registered (re-login to refresh)
- Backend may not be sending pushes (check logs)
- Ensure device is online

**"BLE connection not triggering messages"**
- Verify messaging is enabled in Settings
- Check contacts are configured
- Ensure MessageService is injected into BLEManager
- Test in foreground first, then background

---

## Future Enhancements

### V1.1 Features (Post-Launch)
- [ ] Group messaging (send to multiple contacts at once)
- [ ] Custom message templates per device
- [ ] Message scheduling (send at specific time)
- [ ] Read receipts
- [ ] Rich notifications (images, actions)

### V1.2 Features
- [ ] End-to-end encryption (Signal Protocol)
- [ ] Voice messages (triggered by BLE events)
- [ ] Location sharing (where device connected)
- [ ] Message reactions (emoji responses)

### V2.0 Features
- [ ] Video/photo attachments
- [ ] Device health monitoring (battery, signal strength)
- [ ] Analytics dashboard (connection history, patterns)
- [ ] Multi-device support
- [ ] Desktop client

---

## Additional Resources

### Documentation
- Express.js: https://expressjs.com/
- PostgreSQL: https://www.postgresql.org/docs/
- node-apn: https://github.com/node-apn/node-apn
- Swift URLSession: https://developer.apple.com/documentation/foundation/urlsession
- UserNotifications: https://developer.apple.com/documentation/usernotifications

### Tools
- Postman: API testing
- pgAdmin: PostgreSQL GUI
- PM2: Process monitoring at http://your-server-ip:9615 (if pm2-web enabled)

### Support
- DigitalOcean Tutorials: https://www.digitalocean.com/community/tutorials
- Apple Developer Forums: https://developer.apple.com/forums/
- Stack Overflow: Tag questions with `ios`, `express`, `postgresql`

---

## License

This project will be licensed under **AGPLv3** (GNU Affero General Public License v3.0).

**What this means:**
- ✅ Free to use, modify, and distribute
- ✅ Open source
- ⚠️ If you distribute the app, you must also open-source it
- ⚠️ If you run a modified version on a server (SaaS), you must release the source

**Why AGPLv3:**
- Ensures BLEScanner remains free and open
- Protects against proprietary forks
- Allows community contributions
- Network copyleft (covers server-side code too)

---

## Contact & Contribution

**Repository:** https://github.com/yourusername/BLEScanner (update this)

**Contributing:**
- Fork the repo
- Create a feature branch
- Make changes
- Submit a pull request
- Follow AGPLv3 license terms

**Questions:**
- Open GitHub issues for bugs
- Discussions for feature requests
- Email for security concerns

---

**Last Updated:** 2025-11-04
**Version:** 1.0.0 (Pre-release)
**Status:** In Development
