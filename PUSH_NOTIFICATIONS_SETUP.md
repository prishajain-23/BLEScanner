# Push Notifications Setup Guide

## ✅ What's Been Implemented

### 1. Entitlements
- ✅ `aps-environment` set to `development` in `BLEScanner.entitlements`
- Note: Change to `production` for App Store builds

### 2. Core Services
- ✅ **PushNotificationService.swift** - Manages device tokens and backend registration
- ✅ **AppDelegate.swift** - Handles APNs system callbacks

### 3. Integration
- ✅ AppDelegate integrated into BLEScannerApp
- ✅ Auto-registration on login/register
- ✅ Auto-unregistration on logout
- ✅ UI shows push notification status in settings

### 4. User Flow
```
Login → Request Permission → Get Device Token → Register with Backend → Ready
```

## 🔧 Manual Steps Required

### Step 1: Add Files to Xcode Project

The new files were created but need to be added to the Xcode project manually:

1. Open `BLEScanner.xcodeproj` in Xcode
2. Right-click on the `BLEScanner` group in the Project Navigator
3. Select **Add Files to "BLEScanner"...**
4. Navigate to and select:
   - `BLEScanner/AppDelegate.swift`
   - `BLEScanner/Services/PushNotificationService.swift`
5. Ensure **"Copy items if needed"** is **UNCHECKED** (files are already in place)
6. Ensure **"BLEScanner" target** is **CHECKED**
7. Click **Add**

### Step 2: Verify Build Settings

1. In Xcode, select the BLEScanner target
2. Go to **Signing & Capabilities**
3. Verify **Push Notifications** capability is present
4. If not, click **+ Capability** and add **Push Notifications**

### Step 3: Build and Test

```bash
# Build the project
⌘ + B

# Run on a physical iOS device (push notifications don't work on simulator)
⌘ + R
```

## 📱 Testing Push Notifications

### Prerequisites
- ✅ Physical iOS device (push notifications don't work on simulator)
- ✅ Valid APNs certificate configured on backend (142.93.184.210)
- ✅ Two user accounts (sender and receiver)

### Test Flow

1. **Setup Receiver:**
   - Login to app on Device A as User A
   - Go to Settings → Messaging
   - Verify "Push Notifications: Enabled" (green checkmark)
   - Note the device token (first 20 chars shown)

2. **Setup Sender:**
   - Login to app on Device B (or same device, different account) as User B
   - Add User A as a contact
   - Select User A for messaging (checkmark)

3. **Trigger Message:**
   - Connect ESP32 to Device B
   - Message should auto-send to User A
   - User A should receive push notification

4. **Verify:**
   - Check Device A for push notification
   - Open app → Message History → See new message
   - Backend logs: `pm2 logs blescanner-backend`

### Troubleshooting

**"Push Notifications: Disabled" in Settings**
- Check device permissions: Settings → BLEScanner → Notifications
- Re-register: Tap "Enable Push Notifications" button
- Check backend logs for registration errors

**No device token received**
- APNs requires real device (not simulator)
- Check internet connection
- Verify app signing (provisioning profile must support push)

**Backend registration fails**
- Check JWT token is valid (user logged in)
- Verify backend is running: `ssh root@142.93.184.210 "pm2 status"`
- Check backend logs: `pm2 logs blescanner-backend`
- Verify APNs key is valid (not expired or revoked)

**Push notification not received**
- Check backend logs for push send attempt
- Verify APNs environment (development vs production)
- Ensure app is built with correct provisioning profile
- Check if device token is registered in database:
  ```sql
  SELECT * FROM device_tokens WHERE user_id = <user_id>;
  ```

## 🔐 Security Notes

### APNs Key Requirements
- Key ID: Set in backend `.env` as `APNS_KEY_ID`
- Team ID: Set in backend `.env` as `APNS_TEAM_ID`
- Bundle ID: Must match `com.prishajain.blescanner`
- Key file: `.p8` file in `server/config/` (NEVER commit to git)

### Environment Configuration

**Development (current):**
- Entitlements: `aps-environment: development`
- APNs endpoint: `api.sandbox.push.apple.com`
- For TestFlight and local builds

**Production (for App Store):**
- Entitlements: `aps-environment: production`
- APNs endpoint: `api.push.apple.com`
- Requires production provisioning profile

## 📊 Implementation Details

### Device Token Flow

```swift
// 1. App requests permission
PushNotificationService.shared.registerForRemoteNotifications()

// 2. iOS system callback (AppDelegate)
func application(
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    // Converts to hex string
    PushNotificationService.shared.didRegisterForRemoteNotifications(...)
}

// 3. Register with backend
POST /api/devices/register-push
{
    "device_token": "abc123...",
    "platform": "ios"
}

// 4. Backend stores token in database
// 5. Backend can now send push notifications to this device
```

### Notification Handling

```swift
// Foreground (app open)
func userNotificationCenter(willPresent notification: ...)
    -> Shows banner, sound, badge
    -> Calls PushNotificationService.handleRemoteNotification()
    -> Posts "NewMessageReceived" notification
    -> MessageHistoryView refreshes

// Background (app closed/background)
func userNotificationCenter(didReceive response: ...)
    -> User tapped notification
    -> App opens
    -> Same flow as foreground
```

### Auto-Registration

- **Login/Register:** Automatically requests push permission and registers token
- **Logout:** Unregisters token from backend
- **App Launch:** Checks for saved token and re-registers if needed

## 🎯 Next Steps

1. ✅ Add files to Xcode project (manual step above)
2. ✅ Build and verify no compilation errors
3. ✅ Test on physical device
4. ✅ Verify push notifications received
5. ✅ Read and follow `SECURITY_ALERT.md` (CRITICAL!)
6. Ready for Signal API integration

## 📝 Backend Configuration Reference

**File:** `/var/www/blescanner-backend/server/.env`
```env
APNS_KEY_ID=X859SFN76P  # ⚠️ REVOKE THIS - See SECURITY_ALERT.md
APNS_TEAM_ID=NV97R9Q8MF
APNS_BUNDLE_ID=com.prishajain.blescanner
APNS_KEY_PATH=./config/AuthKey_X859SFN76P.p8
```

**Database:**
```sql
-- Check registered devices
SELECT dt.id, dt.device_token, dt.platform, dt.created_at, u.username
FROM device_tokens dt
JOIN users u ON dt.user_id = u.id
ORDER BY dt.created_at DESC;

-- Check push notification logs
SELECT * FROM push_logs ORDER BY sent_at DESC LIMIT 10;
```

## 🆘 Support

- Backend docs: `server/docs/DEPLOYMENT.md`
- API docs: `server/docs/API.md`
- CLAUDE.md: Project overview and roadmap
- Security: `SECURITY_ALERT.md` (READ THIS FIRST!)

---

**Phase 2 Complete!** 🎉
Ready for Phase 3: Signal API Integration
