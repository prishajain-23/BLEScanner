//
//  SettingsTabView.swift
//  BLEScanner
//
//  Reorganized settings with clear sections
//

import SwiftUI

struct SettingsTabView: View {
    @State var bleManager: BLEManager
    @State private var pushService = PushNotificationService.shared
    @State private var showLogoutConfirmation = false
    @State private var showHelp = false

    var body: some View {
        NavigationStack {
            Form {
                // Messaging Section
                messagingSection

                // Notifications Section
                notificationsSection

                // BLE Connection Section
                bleConnectionSection

                // Account Section
                if AuthService.shared.isAuthenticated {
                    accountSection
                }

                // Advanced Section
                advancedSection

                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    Task { @MainActor in
                        AuthService.shared.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showHelp) {
                SettingsHelpView()
            }
        }
    }

    // MARK: - Messaging Section

    private var messagingSection: some View {
        Section {
            if AuthService.shared.isAuthenticated {
                NavigationLink {
                    MessagingSettingsView(bleManager: bleManager)
                } label: {
                    HStack {
                        Label("Messaging Settings", systemImage: "envelope.fill")
                        Spacer()

                        // Show enabled status and contact count
                        VStack(alignment: .trailing, spacing: 2) {
                            if bleManager.messagingEnabled {
                                Text("Enabled")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if ContactService.shared.selectedContactIds.count > 0 {
                                Text("\(ContactService.shared.selectedContactIds.count) contacts")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text("Login to enable messaging")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Messaging")
        } footer: {
            if AuthService.shared.isAuthenticated {
                Text("Configure auto-messaging and contacts")
            } else {
                Text("Sign in to send automatic messages when your Medal of Freedom connects")
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Push Notifications", systemImage: "bell.fill")
                Spacer()

                // Show status in same style as messaging settings
                VStack(alignment: .trailing, spacing: 2) {
                    if pushService.isRegistered {
                        Text("Enabled")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Disabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !pushService.isRegistered {
                Button("Enable Push Notifications") {
                    pushService.registerForRemoteNotifications()
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive messages from contacts even when the app is closed")
        }
    }

    // MARK: - BLE Connection Section

    private var bleConnectionSection: some View {
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
            Text("Medal of Freedom Connection")
        } footer: {
            if bleManager.autoConnectEnabled {
                Text("Auto-connect will attempt up to \(BLEConfiguration.maxReconnectionAttempts) reconnections. Background reconnection uses more battery.")
            } else {
                Text("Automatically connect to your registered Medal of Freedom when discovered")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            HStack {
                Label("Username", systemImage: "person.circle.fill")
                Spacer()
                Text(AuthService.shared.currentUser?.username ?? "Unknown")
                    .foregroundStyle(.secondary)
            }

            if let contactCount = AuthService.shared.currentUser?.contactCount {
                HStack {
                    Label("Contacts", systemImage: "person.2.fill")
                    Spacer()
                    Text("\(contactCount)")
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
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

            HStack {
                Text("Max Reconnection Attempts")
                Spacer()
                Text("\(BLEConfiguration.maxReconnectionAttempts)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Connection Timeout")
                Spacer()
                Text("\(Int(BLEConfiguration.connectionTimeout))s")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Advanced")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                AutomationGuideView()
            } label: {
                Label("Help & Guide", systemImage: "questionmark.circle")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Helper

    private var connectionStateText: String {
        switch bleManager.connectionState {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        }
    }
}

#Preview {
    SettingsTabView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
