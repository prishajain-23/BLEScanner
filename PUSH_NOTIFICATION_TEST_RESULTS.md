# Push Notification System - Test Results & Documentation

**Date:** November 12, 2025
**Status:** ✅ COMPLETE - All tests passed

---

## Summary

Successfully rotated compromised APNs key, fixed critical bugs, and validated push notifications across all app states (foreground, background, killed).

---

## What Was Accomplished

### 1. APNs Key Rotation (Security Fix)
**Problem:** APNs private key X859SFN76P was previously committed to git and exposed.

**Actions Taken:**
- ✅ Revoked compromised key X859SFN76P in Apple Developer Portal (3:40PM EST, Nov 12, 2025)
- ✅ Generated new APNs authentication key: **N2UGRH67CT**
- ✅ Updated local configuration files (server/.env, server/config/README.md, CLAUDE.md)
- ✅ Deployed new key to production server (142.93.184.210)
- ✅ Verified .p8 files are in .gitignore to prevent future exposure

**Current APNs Configuration:**
```
Key ID: N2UGRH67CT
Team ID: NV97R9Q8MF
Bundle ID: com.prishajain.medaloffreedom
Environment: Development (Sandbox)
Server: 142.93.184.210
```

---

### 2. Bundle ID Mismatch Fix
**Problem:** Backend was configured for `com.prishajain.blescanner` but actual app uses `com.prishajain.medaloffreedom`, causing `DeviceTokenNotForTopic` APNs errors.

**Solution:**
- Updated APNS_TOPIC in server/.env to `com.prishajain.medaloffreedom`
- Restarted backend with `--update-env` flag
- Regenerated device tokens by reinstalling app on test devices

---

### 3. Contact Persistence Bug Fix
**Problem:** Selected contacts were not persisting across app restarts, breaking the auto-messaging use case.

**Root Cause:** Contact selections were only loaded when ContactListView appeared, not on app launch.

**Solution:**
- Modified ContactService.swift:fetchContacts() to automatically call loadSelectedContacts() after fetching
- Added .task{} in MainTabView to fetch contacts on app launch
- Removed duplicate loadSelectedContacts() call in ContactListView

**Files Modified:**
- BLEScanner/Services/ContactService.swift:54
- BLEScanner/Views/MainTabView.swift:42-45
- BLEScanner/Views/Contacts/ContactListView.swift:39-41

**Result:** Selected contacts now persist across app restarts and are available for background messaging.

---

## Push Notification Test Results

**Test Environment:**
- Device 1 (Sender): wednesday_send user
- Device 2 (Receiver): wednesday_receive user
- Backend: 142.93.184.210 (Development/Sandbox APNs)

### Test 1: Foreground State ✅
**Setup:** Receiving device with app open and active

**Result:** SUCCESS
- ✅ Notification received via AppDelegate callback
- ✅ Banner displayed at top of screen (iOS native)
- ✅ Sound played
- ✅ Message content displayed
- ✅ Message history auto-refreshed

**Console Output:**
```
📨 Received remote notification: [AnyHashable("device_name"): Test Device, ...]
📬 Message: wednesday_send - Test Device: New message
🌐 API Request: GET http://142.93.184.210/api/messages/history
✅ Fetched 1 messages (offset: 0)
🔓 Decrypted message from user 12
```

---

### Test 2: Background State ✅
**Setup:** App running but in background (home screen visible)

**Result:** SUCCESS
- ✅ Banner notification appeared on screen
- ✅ Notification sound played
- ✅ Badge count updated on app icon
- ✅ Tapping notification brought app to foreground
- ✅ Message visible in history

---

### Test 3: Killed State ✅
**Setup:** App completely force-quit (not in app switcher)

**Result:** SUCCESS
- ✅ Notification received even with app fully closed
- ✅ Notification sound played
- ✅ Badge count updated on app icon
- ✅ Tapping notification launched the app
- ✅ Message loaded in history after launch

---

## Device Tokens Registered

**Sender Device (wednesday_send):**
- Token: [registered during testing]
- User ID: 12
- Status: Active

**Receiver Device (wednesday_receive):**
- Token: `4c504b014e016a3ec40b8c0102f7c2e67fa972a7e618aabeb41d7a4d6e52a848`
- User ID: [receiver user ID]
- Status: Active, tested in all states

---

## Issues Encountered & Resolved

### Issue 1: BadDeviceToken Error
**Error:** APNs responded with status 400, reason: "BadDeviceToken"

**Cause:** Old device tokens were generated with the revoked APNs key X859SFN76P.

**Resolution:** Device tokens automatically regenerated after:
1. Deploying new APNs key to server
2. Deleting and reinstalling app on test devices
3. Fresh login and notification permission grant

---

### Issue 2: DeviceTokenNotForTopic Error
**Error:** APNs responded with status 400, reason: "DeviceTokenNotForTopic"

**Cause:** Bundle ID mismatch between backend config (`com.prishajain.blescanner`) and actual app (`com.prishajain.medaloffreedom`).

**Resolution:**
1. Updated APNS_TOPIC in server/.env
2. Restarted backend with `pm2 restart blescanner-backend --update-env`
3. Regenerated device tokens by reinstalling app

---

### Issue 3: Contact Selections Not Persisting
**Error:** Selected contacts reset to empty after app restart.

**Cause:** loadSelectedContacts() only called when ContactListView appeared, not on app launch.

**Resolution:** Modified ContactService to auto-load selections after fetch, added fetch call on MainTabView launch.

---

## Technical Implementation Details

### Push Notification Flow
1. User logs in → App requests notification permissions
2. iOS generates device token → AppDelegate receives token
3. PushNotificationService converts token to hex → Registers with backend
4. Backend stores token in users.device_token column
5. Message sent → Backend retrieves recipient device tokens
6. Backend sends push via node-apn to APNs
7. APNs delivers to device → AppDelegate/UNUserNotificationCenterDelegate handles
8. App displays notification based on state (foreground/background/killed)

### Key Files
- **iOS:**
  - AppDelegate.swift - APNs callbacks
  - PushNotificationService.swift - Token management
  - BLEScannerApp.swift - Auto-registration on login

- **Backend:**
  - server/services/PushService.js - APNs provider
  - server/routes/devices.js - Token registration endpoints
  - server/routes/messages.js - Message send + push trigger

---

## Configuration Files

### server/.env
```bash
APNS_KEY_ID=N2UGRH67CT
APNS_TEAM_ID=NV97R9Q8MF
APNS_TOPIC=com.prishajain.medaloffreedom
APNS_KEY_PATH=/Users/prishajain/Desktop/GitHub/BLEScanner/server/config/AuthKey_N2UGRH67CT.p8
APNS_PRODUCTION=false  # Sandbox/Development
```

### Production Server (.env on 142.93.184.210)
```bash
APNS_KEY_ID=N2UGRH67CT
APNS_TEAM_ID=NV97R9Q8MF
APNS_TOPIC=com.prishajain.medaloffreedom
APNS_KEY_PATH=./config/AuthKey_N2UGRH67CT.p8
APNS_PRODUCTION=false
```

---

## Security Notes

### ✅ Implemented
- APNs private key (.p8) added to .gitignore
- Compromised key revoked in Apple Developer Portal
- New key stored securely (never committed to git)
- JWT tokens stored in iOS Keychain (not UserDefaults)

### ⚠️ TODO (Future)
- Add HTTPS/SSL to backend (Let's Encrypt)
- Implement rate limiting for push notification endpoints
- Add push notification retry logic for failed sends
- Monitor APNs feedback service for invalid tokens

---

## Production Deployment Checklist

When moving to production:

- [ ] Create **Production** APNs key (or switch APNS_PRODUCTION=true)
- [ ] Update server/.env with production key
- [ ] Build iOS app with **App Store** or **Ad Hoc** provisioning profile
- [ ] Enable HTTPS on backend server
- [ ] Test push notifications in production environment
- [ ] Monitor PM2 logs for push failures
- [ ] Set up APNs feedback service monitoring

---

## Troubleshooting Guide

### Push notifications not received?

1. **Check device token registration:**
   ```
   Look for: ✅ Device token registered with backend
   ```

2. **Check backend logs:**
   ```bash
   ssh root@142.93.184.210
   pm2 logs blescanner-backend | grep -i push
   ```

3. **Verify APNs configuration:**
   - Bundle ID matches: `com.prishajain.medaloffreedom`
   - Environment matches: Development = Sandbox, Production = Production
   - Device token is fresh (not from old key)

4. **Check iOS notification settings:**
   - Settings → Medal of Freedom → Notifications
   - Ensure all permissions are enabled

5. **Common errors:**
   - `BadDeviceToken` → Token from wrong APNs key, reinstall app
   - `DeviceTokenNotForTopic` → Bundle ID mismatch, check APNS_TOPIC
   - No token registered → Check notification permissions granted

---

## Next Steps / Future Enhancements

### Immediate (Optional)
- [ ] Test with actual BLE Medal of Freedom device connection
- [ ] Verify auto-messaging works in background
- [ ] Test with multiple recipients

### Future (V1.1+)
- [ ] Rich push notifications (images, actions)
- [ ] Silent push notifications for background refresh
- [ ] Push notification analytics
- [ ] Custom notification sounds
- [ ] Notification grouping/threading
- [ ] Push notification history/logs

---

## Test Sign-Off

**Tested By:** Development Team
**Date:** November 12-13, 2025
**Environment:** Development/Sandbox
**Status:** ✅ All tests passed

**Test Scenarios Completed:**
- [x] Foreground notification delivery
- [x] Background notification delivery
- [x] Killed app notification delivery
- [x] Notification sound playback
- [x] Badge count updates
- [x] Tap to open app
- [x] Message decryption after notification
- [x] Contact persistence across restarts
- [x] Device token registration
- [x] APNs key rotation

---

**Last Updated:** November 13, 2025
