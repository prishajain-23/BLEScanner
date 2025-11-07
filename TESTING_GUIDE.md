# BLEScanner - Testing Guide

## Build Status: ✅ READY FOR DEVICE TESTING

**Last Build**: Success (November 6, 2025)
**Branch**: messages
**Simulator**: Builds successfully
**Device**: Ready to test

---

## What's New in This Build

### 🚀 Performance Improvements

#### 1. Keyboard Input Lag - FIXED ⚡
**Test**: Type rapidly in search fields
- **Device search** (Connections tab): Should respond instantly
- **User search** (Add Contact): Should respond smoothly
- **Expected**: No lag, stuttering, or freezing while typing

#### 2. Debounced Search - IMPLEMENTED 🔍
**Test**: Type a search query character by character
- Device search waits 150ms before filtering
- User search waits 400ms before API call
- **Expected**: See "Searching..." only after you stop typing

#### 3. Message Pagination - IMPLEMENTED 📄
**Test**: Open Message History
- Initial load: Only 20 messages
- Scroll to bottom: Automatically loads 20 more
- **Expected**: Fast initial load, smooth infinite scroll
- **Expected**: "Loading more..." indicator appears when fetching

#### 4. Background Thread Filtering - IMPLEMENTED 🔄
**Test**: Search with many BLE devices nearby
- Type in device search while scanning
- **Expected**: UI remains responsive, no freezing
- **Expected**: Filtering happens smoothly in background

---

## Testing Checklist

### ✅ Pre-Testing Setup

1. **Build Configuration**
   ```
   Scheme: BLEScanner
   Destination: Your iPhone (connected via USB)
   Build Configuration: Debug
   ```

2. **Required Permissions** (will be requested on first launch)
   - [ ] Bluetooth (BLE scanning)
   - [ ] Notifications (connection alerts)
   - [ ] Background Bluetooth (if testing auto-connect)

3. **Backend API**
   - Production API: `http://142.93.184.210`
   - Test users: `alice` / `bob` (password: whatever you set)
   - Status: Running and accessible

---

### 🔍 Performance Testing

#### Test 1: Device Search Performance
1. Start BLE scanning (should find ESP32 or other devices)
2. Type rapidly in the search field: "ESP", delete, "Living", delete
3. **✅ Pass**: No lag, instant response
4. **❌ Fail**: Keyboard freezes, stutters, or delays

#### Test 2: User Search Performance
1. Tap Messages tab → Contacts → Add Contact (+)
2. Type a username slowly: "a", wait, "l", wait, "i"
3. Observe "Searching..." appears only after 400ms pause
4. **✅ Pass**: Debouncing works, search triggers after typing stops
5. **❌ Fail**: API call on every keystroke, excessive "Searching..."

#### Test 3: Message Pagination
1. Login with test account (alice or bob)
2. Go to Messages tab → History
3. If you have < 20 messages, add more via web/API
4. Initial load should show 20 messages
5. Scroll to bottom → "Loading more..." → next 20 appear
6. **✅ Pass**: Fast initial load, smooth pagination
7. **❌ Fail**: Loads all messages at once, slow initial load

#### Test 4: Background Filtering
1. Start scanning for BLE devices (find 5+ devices if possible)
2. Type in search field while devices are still being discovered
3. **✅ Pass**: UI remains responsive, search works smoothly
4. **❌ Fail**: UI freezes or stutters while filtering

---

### 🔌 BLE Connection Testing

#### Test 5: Device Scanning
- [ ] Scan button works
- [ ] Devices appear in list with names/UUIDs
- [ ] Search filter works (filters by device name)
- [ ] Clear search (X button) works

#### Test 6: Connection Flow
- [ ] Connect to ESP32 device
- [ ] Status bar shows "Connected"
- [ ] Device name appears in status bar
- [ ] Disconnect button works
- [ ] Status returns to "Disconnected"

#### Test 7: Auto-Connect
- [ ] Enable auto-connect for a device
- [ ] Move out of range / power off device
- [ ] Move back in range / power on device
- [ ] App automatically reconnects
- [ ] "Reconnecting..." banner shows during attempts

---

### 💬 Messaging Testing

#### Test 8: Authentication
- [ ] Register new user (or use alice/bob)
- [ ] Login succeeds
- [ ] Token persists after app restart
- [ ] Logout clears token

#### Test 9: Contact Management
- [ ] Search for users (debounced search)
- [ ] Add contact
- [ ] Contact appears in list
- [ ] Select contact for messaging (checkbox)
- [ ] Remove contact

#### Test 10: Message Sending
- [ ] Enable auto-messaging in Settings
- [ ] Select contacts to message
- [ ] Connect to BLE device
- [ ] Message sent automatically
- [ ] Check Message History → message appears

#### Test 11: Message History
- [ ] View message history
- [ ] Pagination works (20 per page)
- [ ] Pull to refresh works
- [ ] Sent vs Received indicators correct
- [ ] Timestamps display properly

---

### 🔔 Notification Testing

#### Test 12: Push Notifications (Optional - APNs key needed)
**Note**: APNs key was exposed and needs to be replaced
- [ ] Register device token with backend
- [ ] Receive push notification when message arrives
- [ ] Tap notification → opens app
- [ ] Notification shows sender and message

---

### 🎨 UI/UX Testing

#### Test 13: Navigation
- [ ] Tab bar not implemented yet (single view)
- [ ] Settings sheet opens
- [ ] Contact list sheet opens
- [ ] Message history sheet opens
- [ ] All "Done" buttons work

#### Test 14: Responsive UI
- [ ] Keyboard doesn't cover input fields
- [ ] Dismissing keyboard works (tap outside)
- [ ] Lists scroll smoothly
- [ ] Loading indicators show during operations
- [ ] Error messages display properly

---

### 📱 Device-Specific Testing

#### Test 15: App Lifecycle
- [ ] App works when foregrounded
- [ ] App works when backgrounded (BLE continues)
- [ ] App works after device lock
- [ ] App restores state after termination

#### Test 16: Memory & Performance
- [ ] No excessive battery drain
- [ ] No memory leaks (use Xcode Instruments)
- [ ] Scrolling is smooth (60 FPS)
- [ ] No crashes during testing

---

## Known Issues

### ⚠️ Security Issue - APNs Key Exposed
**Status**: FIXED in git, but key needs replacement
**Action Required**:
1. Revoke APNs key `X859SFN76P` in Apple Developer Portal
2. Generate new APNs key
3. Update production server with new key
4. Test push notifications with new key

**Impact**: Push notifications won't work until key is replaced

### 📋 Planned Features (Not Yet Implemented)
- [ ] TabView UI (see UI_IMPROVEMENT_PLAN.md)
- [ ] Unread message badges
- [ ] Message read receipts
- [ ] Group messaging
- [ ] Custom message templates

---

## Performance Benchmarks

### Expected Performance Targets

| Metric | Target | How to Test |
|--------|--------|-------------|
| Keyboard input lag | < 16ms (instant) | Type rapidly in search |
| Device search (100 devices) | < 100ms | Scan with many devices |
| Initial message load | < 500ms | Open message history |
| Pagination load | < 300ms | Scroll to bottom |
| BLE connection time | < 3s | Connect to device |
| API response time | < 1s | Search users, add contact |

---

## Debugging Tips

### If keyboard is still laggy:
1. Check Xcode console for excessive logs
2. Profile with Instruments (Time Profiler)
3. Look for main thread blocking
4. Verify debouncer is working (check 150ms/400ms delays)

### If messages don't send:
1. Check Settings → Messaging → Auto-Send is enabled
2. Verify contacts are selected (checkboxes)
3. Check network connection
4. View Xcode console for error messages
5. Test API directly with curl

### If build fails:
1. Clean build folder (Cmd+Shift+K)
2. Delete DerivedData folder
3. Restart Xcode
4. Check all files are added to target

---

## Test Device Requirements

### Minimum Requirements
- iOS 17.6+ (deployment target)
- iPhone with Bluetooth
- Internet connection (for messaging API)
- ESP32 or compatible BLE device (for BLE testing)

### Recommended Setup
- iPhone 12 or newer
- iOS 18+
- Strong WiFi connection
- Multiple BLE devices for thorough testing

---

## Reporting Issues

If you find issues during testing:

1. **Note the exact steps to reproduce**
2. **Check Xcode console for error messages**
3. **Screenshot if UI-related**
4. **Note device model and iOS version**
5. **Check network connectivity**

Example issue report:
```
Issue: Keyboard lag in user search
Device: iPhone 14 Pro, iOS 18.0
Steps:
1. Go to Messages → Add Contact
2. Type rapidly: "testuser"
3. Keyboard freezes for 1-2 seconds
Console: [paste relevant errors]
```

---

## Success Criteria

### ✅ Build is ready for production if:
- [ ] All Performance Tests (1-4) pass
- [ ] All BLE Tests (5-7) pass
- [ ] All Messaging Tests (8-11) pass
- [ ] No crashes during 30-minute testing session
- [ ] UI is responsive and smooth
- [ ] API calls complete successfully

### ⚠️ Needs more work if:
- [ ] Keyboard lag persists
- [ ] UI freezes or stutters
- [ ] Messages fail to send
- [ ] Crashes occur
- [ ] API errors persist

---

## Next Steps After Testing

### If tests pass:
1. Review UI_IMPROVEMENT_PLAN.md
2. Implement TabView UI (~2.5 hours)
3. Add unread message badges
4. Replace APNs key for push notifications
5. Prepare for TestFlight release

### If tests fail:
1. Document specific failing tests
2. Review Xcode console logs
3. Profile with Instruments if performance issue
4. Fix critical issues before TabView implementation

---

**Last Updated**: November 6, 2025
**Build Version**: Debug
**Ready for**: Device Testing ✅
