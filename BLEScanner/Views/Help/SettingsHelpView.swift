//
//  SettingsHelpView.swift
//  BLEScanner
//
//  Help and instructions for the Settings tab
//

import SwiftUI

struct SettingsHelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        Text("Settings & Configuration")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Learn how to configure messaging, notifications, and automation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Messaging Setup
                    HelpSection(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: "Messaging Setup"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Configure auto-messaging when your device connects:")
                                .fontWeight(.medium)

                            HelpStep(number: 1, text: "Enable \"Auto-Send Messages\" toggle")
                            HelpStep(number: 2, text: "Tap \"Messaging Settings\" to customize")
                            HelpStep(number: 3, text: "Edit your message template")
                            HelpStep(number: 4, text: "Add and select contacts who will receive messages")

                            Text("Use {device} and {time} placeholders in your template for dynamic content.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Push Notifications
                    HelpSection(
                        icon: "bell.fill",
                        iconColor: .red,
                        title: "Push Notifications"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Why you need push notifications:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Receive messages from contacts even when app is closed")
                            BulletPoint(text: "Get notified instantly when someone sends you a message")
                            BulletPoint(text: "Required for the messaging system to work properly")

                            Text("If disabled, tap \"Enable Push Notifications\" and grant permission when prompted.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Device Management
                    HelpSection(
                        icon: "antenna.radiowaves.left.and.right",
                        iconColor: .green,
                        title: "BLE Connection Settings"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manage your device connection behavior:")
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 8) {
                                SettingDescription(
                                    name: "Enable Auto-Connect",
                                    description: "Automatically connect to your registered device when in range"
                                )

                                SettingDescription(
                                    name: "Background Reconnection",
                                    description: "Allow reconnection attempts when app is in background (uses more battery)"
                                )

                                SettingDescription(
                                    name: "Clear Auto-Connect Device",
                                    description: "Forget the current device to register a new one"
                                )
                            }
                        }
                    }

                    // Shortcuts Automation
                    HelpSection(
                        icon: "square.stack.3d.up.fill",
                        iconColor: .purple,
                        title: "Shortcuts Automation (Advanced)"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BLEScanner provides App Intents for iOS Shortcuts:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Check Medal of Freedom connection status")
                            BulletPoint(text: "Get connected device name")
                            BulletPoint(text: "Check last connection time")

                            Text("Setting up automation:")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            HelpStep(number: 1, text: "Open Shortcuts app")
                            HelpStep(number: 2, text: "Create a new automation")
                            HelpStep(number: 3, text: "Choose a trigger (App Opens, Time, Location)")
                            HelpStep(number: 4, text: "Add \"Check BLEScanner Connection\" action")
                            HelpStep(number: 5, text: "Add conditional actions based on result")

                            AutomationExample(
                                trigger: "When I arrive home",
                                action: "Check if Medal of Freedom is connected, then turn on lights"
                            )

                            AutomationExample(
                                trigger: "When app opens",
                                action: "If Medal of Freedom connected, send notification with device name"
                            )
                        }
                    }

                    // Account Management
                    HelpSection(
                        icon: "person.circle.fill",
                        iconColor: .orange,
                        title: "Account Management"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your account information:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Username: Used by others to find and add you as a contact")
                            BulletPoint(text: "Contacts: Number of people you've added")
                            BulletPoint(text: "Logout: Sign out and return to login screen")

                            Text("Note: Logging out will not delete your messages or contacts. They'll be available when you log back in.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Advanced Info
                    HelpSection(
                        icon: "info.circle.fill",
                        iconColor: .gray,
                        title: "Advanced Information"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connection details:")
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 6) {
                                InfoRow(label: "Max Reconnection Attempts", value: "\(BLEConfiguration.maxReconnectionAttempts)")
                                InfoRow(label: "Connection Timeout", value: "\(Int(BLEConfiguration.connectionTimeout))s")
                                InfoRow(label: "Encryption", value: "CryptoKit E2EE")
                            }

                            Text("All messages are end-to-end encrypted using CryptoKit before being sent to contacts.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Settings Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct SettingDescription: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.callout)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct AutomationExample: View {
    let trigger: String
    let action: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trigger: \(trigger)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Action: \(action)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsHelpView()
}
