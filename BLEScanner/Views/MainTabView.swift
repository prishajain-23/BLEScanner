//
//  MainTabView.swift
//  BLEScanner
//
//  Main tab navigation for the app
//

import SwiftUI

struct MainTabView: View {
    @State private var bleManager: BLEManager
    @State private var selectedTab = 0

    init(bleManager: BLEManager) {
        self._bleManager = State(initialValue: bleManager)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Connections Tab
            ConnectionsView(bleManager: bleManager)
                .tabItem {
                    Label("Connections", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)

            // Messages Tab
            MessagesTabView()
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)

            // Settings Tab
            SettingsTabView(bleManager: bleManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
