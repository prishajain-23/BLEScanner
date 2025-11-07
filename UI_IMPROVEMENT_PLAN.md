# UI Improvement Plan - TabView Implementation

## Overview
Transform BLEScanner from a single-view app to a modern tab-based interface with three main sections: Connections, Messages, and Settings.

---

## Performance Improvements Completed ✅

### 1. Keyboard Input Lag - FIXED
- **Problem**: Search fields caused UI lag on every keystroke
- **Solution**:
  - Added `Debouncer` utility (150ms for devices, 400ms for users)
  - Moved filtering off main thread using `Task.detached`
  - Reduced unnecessary view re-renders

### 2. Main Actor Optimization - FIXED
- **Problem**: Excessive `await MainActor.run` calls blocking UI
- **Solution**:
  - Removed individual @MainActor properties from `ContactService`
  - Added @MainActor at function level where needed
  - Batched state updates instead of multiple MainActor hops

### 3. Pagination - IMPLEMENTED
- **Problem**: Loading 50 messages at once, causing slow initial load
- **Solution**:
  - Implemented infinite scroll pagination (20 messages per page)
  - Added `loadMoreMessages()` with offset parameter
  - Backend API now supports `?limit=20&offset=0` query params
  - Shows "Loading more..." indicator while fetching

### 4. Background Thread Filtering - IMPLEMENTED
- **Problem**: Device filtering blocked main thread
- **Solution**:
  - `filteredPeripherals` moved to background using `Task.detached`
  - UI updates only after filtering completes
  - Debounced to prevent excessive filtering

---

## New UI Structure - TabView

### Architecture

```
TabView (bottom navigation)
├── Tab 1: Connections (BLE Scanner)
│   ├── Device List
│   ├── Search Bar
│   ├── Connection Status
│   └── Scan Controls
│
├── Tab 2: Messages
│   ├── Message History (paginated)
│   ├── Contact List
│   └── Quick Actions
│
└── Tab 3: Settings
    ├── Auto-Connection Settings
    ├── Notification Settings
    ├── Messaging Settings
    └── App Info
```

---

## Implementation Plan

### Phase 1: Create Tab Structure (30 min)

**File**: `BLEScanner/Views/MainTabView.swift` (NEW)

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var notificationManager = NotificationManager()
    @State private var shortcutManager = ShortcutManager()
    @State private var bleManager: BLEManager

    init() {
        let notifManager = NotificationManager()
        let shortManager = ShortcutManager()
        _notificationManager = State(initialValue: notifManager)
        _shortcutManager = State(initialValue: shortManager)
        _bleManager = State(initialValue: BLEManager(
            notificationManager: notifManager,
            shortcutManager: shortManager
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Connections
            ConnectionsView(
                bleManager: bleManager,
                notificationManager: notificationManager,
                shortcutManager: shortcutManager
            )
            .tabItem {
                Label("Connections", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(0)

            // Tab 2: Messages
            MessagesTabView()
                .tabItem {
                    Label("Messages", systemImage: "envelope.fill")
                }
                .tag(1)
                .badge(unreadMessageCount)

            // Tab 3: Settings
            SettingsTabView(
                bleManager: bleManager,
                notificationManager: notificationManager,
                shortcutManager: shortcutManager
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
    }

    private var unreadMessageCount: Int {
        // TODO: Implement unread message tracking
        0
    }
}
```

**Update**: `BLEScannerApp.swift`
- Replace `ContentView()` with `MainTabView()`

---

### Phase 2: Connections Tab (20 min)

**File**: `BLEScanner/Views/Connections/ConnectionsView.swift` (NEW)

Extract device scanning UI from current `ContentView.swift`:

```swift
struct ConnectionsView: View {
    var bleManager: BLEManager
    var notificationManager: NotificationManager
    var shortcutManager: ShortcutManager

    @State private var searchText = ""
    @State private var filteredResults: [DiscoveredPeripheral] = []
    @State private var showAutomationGuide = false
    @Environment(\.scenePhase) var scenePhase

    private let searchDebouncer = Debouncer(delay: .milliseconds(150))

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                statusBar

                // Reconnection warning
                if bleManager.isReconnecting {
                    reconnectionBanner
                }

                // Search bar
                searchBar

                // Device list
                deviceList

                // Bottom controls
                bottomControls
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAutomationGuide = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showAutomationGuide) {
                AutomationGuideView()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Handle app lifecycle
            }
        }
    }

    // ... (move all existing views from ContentView)
}
```

---

### Phase 3: Messages Tab (30 min)

**File**: `BLEScanner/Views/Messages/MessagesTabView.swift` (NEW)

```swift
struct MessagesTabView: View {
    @State private var contactService = ContactService.shared
    @State private var showAddContact = false
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment control: History | Contacts
                Picker("View", selection: $selectedSegment) {
                    Text("History").tag(0)
                    Text("Contacts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedSegment == 0 {
                    MessageHistoryView()
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    ContactListView()
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedSegment == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddContact = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView()
            }
        }
    }
}
```

**Update**: `MessageHistoryView.swift` and `ContactListView.swift`
- Remove individual navigation stacks (handled by parent)
- Remove "Done" buttons (no longer needed in tabs)

---

### Phase 4: Settings Tab (20 min)

**File**: `BLEScanner/Views/Settings/SettingsTabView.swift` (NEW)

```swift
struct SettingsTabView: View {
    var bleManager: BLEManager
    var notificationManager: NotificationManager
    var shortcutManager: ShortcutManager

    var body: some View {
        NavigationStack {
            Form {
                // Auto-Connection Section
                Section {
                    Toggle("Enable Auto-Connect", isOn: Binding(
                        get: { bleManager.autoConnectEnabled },
                        set: { bleManager.autoConnectEnabled = $0 }
                    ))

                    if bleManager.autoConnectEnabled {
                        Toggle("Background Reconnection", isOn: Binding(
                            get: { bleManager.allowBackgroundReconnection },
                            set: { bleManager.allowBackgroundReconnection = $0 }
                        ))

                        Button("Clear Auto-Connect Device") {
                            bleManager.clearAutoConnectDevice()
                        }
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Auto-Connection")
                } footer: {
                    if bleManager.autoConnectEnabled {
                        Text("Auto-connect will attempt up to \(BLEConfiguration.maxReconnectionAttempts) reconnections.")
                    }
                }

                // Notifications Section
                Section {
                    Toggle("Send Notifications", isOn: Binding(
                        get: { notificationManager.notificationsEnabled },
                        set: { notificationManager.notificationsEnabled = $0 }
                    ))
                } header: {
                    Text("Notifications")
                }

                // iOS Shortcuts Section
                Section {
                    TextField("Shortcut Name", text: Binding(
                        get: { shortcutManager.shortcutName },
                        set: { shortcutManager.shortcutName = $0 }
                    ))
                    .autocapitalization(.none)
                } header: {
                    Text("iOS Shortcuts")
                }

                // Messaging Section
                Section {
                    if AuthService.shared.isAuthenticated {
                        NavigationLink {
                            MessagingSettingsView(bleManager: bleManager)
                        } label: {
                            Label("Messaging Settings", systemImage: "envelope.fill")
                        }

                        HStack {
                            Text("Auto-Send")
                            Spacer()
                            Text(bleManager.messagingEnabled ? "Enabled" : "Disabled")
                                .foregroundStyle(.secondary)
                        }

                        Button("Logout") {
                            Task {
                                await AuthService.shared.logout()
                            }
                        }
                        .foregroundStyle(.red)
                    } else {
                        NavigationLink {
                            AuthView()
                        } label: {
                            Label("Login / Register", systemImage: "person.circle")
                        }
                    }
                } header: {
                    Text("Messaging")
                }

                // Status Section
                Section {
                    HStack {
                        Text("Connection State")
                        Spacer()
                        Text(connectionStateText)
                            .foregroundStyle(.secondary)
                    }

                    if let peripheral = bleManager.connectedPeripheral {
                        HStack {
                            Text("Connected Device")
                            Spacer()
                            Text(peripheral.name ?? "Unknown")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Status")
                }

                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/yourusername/BLEScanner")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var connectionStateText: String {
        switch bleManager.connectionState {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}
```

---

### Phase 5: Polish & Refinements (30 min)

1. **Update MessageHistoryView**
   - Remove navigation stack wrapper
   - Remove "Done" button

2. **Update ContactListView**
   - Remove navigation stack wrapper
   - Remove "Done" button

3. **Add Badge for Unread Messages**
   - Create `@Observable` class for tracking unread count
   - Update badge in MainTabView

4. **Authentication State Handling**
   - Show login prompt in Messages tab if not authenticated
   - Add badge to Settings tab when logged in

5. **Tab Bar Appearance**
   - Consider custom accent color
   - Add haptic feedback on tab selection (optional)

---

## Visual Mockup

```
┌──────────────────────────────────────┐
│  BLEScanner                     [i]  │ ← Navigation title
├──────────────────────────────────────┤
│  🔴 Disconnected                     │ ← Status bar
├──────────────────────────────────────┤
│  [Search devices____________]  [x]   │ ← Search
├──────────────────────────────────────┤
│  📱 ESP32 Living Room               │
│     UUID: ABC-123...                 │
│     [Details ▼] [Connect] [Auto]    │
│                                      │
│  📱 ESP32 Garage                    │
│     UUID: DEF-456...                 │
│     [Details ▼] [Connect] [Auto]    │
│                                      │
├──────────────────────────────────────┤
│  [Scan for Devices]                  │ ← Bottom button
└──────────────────────────────────────┘
│ 📡 Connections  ✉️ Messages  ⚙️ Settings │ ← Tab bar
└──────────────────────────────────────┘
```

---

## Benefits of TabView Approach

### User Experience
✅ **Clearer navigation** - Each feature has dedicated space
✅ **Faster access** - No drilling into settings for messages
✅ **Better discoverability** - Users can explore all features
✅ **Modern iOS pattern** - Familiar tab-based interface

### Performance
✅ **Lazy loading** - Tabs load content only when selected
✅ **State preservation** - Each tab maintains its state
✅ **Reduced view hierarchy** - Simpler navigation structure

### Development
✅ **Better separation of concerns** - Each tab is independent
✅ **Easier testing** - Test tabs individually
✅ **Scalable** - Easy to add more tabs in future

---

## Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Create MainTabView structure | 30 min | ⏳ Pending |
| 2 | Extract ConnectionsView | 20 min | ⏳ Pending |
| 3 | Create MessagesTabView | 30 min | ⏳ Pending |
| 4 | Create SettingsTabView | 20 min | ⏳ Pending |
| 5 | Polish & refinements | 30 min | ⏳ Pending |
| **Total** | | **~2.5 hours** | |

---

## Testing Checklist

After implementation:
- [ ] Connections tab - device scanning works
- [ ] Connections tab - search with debouncing works
- [ ] Messages tab - history pagination works
- [ ] Messages tab - contact list works
- [ ] Messages tab - segment switching works
- [ ] Settings tab - all toggles work
- [ ] Settings tab - navigation to sub-views works
- [ ] Tab switching preserves state
- [ ] Badge shows unread count
- [ ] Authentication flow works in tabs
- [ ] BLE operations work while in Messages/Settings tabs

---

## Future Enhancements

### V1.1 (Post-TabView)
- [ ] Unread message badge on Messages tab
- [ ] Pull-to-refresh on all tabs
- [ ] Swipe actions on contact list
- [ ] Message search in Messages tab
- [ ] Recently connected devices in Connections tab

### V1.2
- [ ] Custom tab bar with animations
- [ ] Tab bar hides when scrolling
- [ ] iPad split view support
- [ ] Drag-and-drop between tabs

---

## Notes

- All performance improvements are backward compatible
- Existing functionality preserved during refactoring
- Can implement gradually (one tab at a time)
- Authentication state handled gracefully
- BLE manager shared across all tabs

---

**Created**: November 6, 2025
**Status**: Ready for implementation
**Estimated effort**: 2-3 hours
