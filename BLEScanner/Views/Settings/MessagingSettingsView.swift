//
//  MessagingSettingsView.swift
//  BLEScanner
//
//  Main messaging settings and management screen
//

import SwiftUI

struct MessagingSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var contactService = ContactService.shared
    var bleManager: BLEManager

    @State private var showContacts = false
    @State private var showMessageHistory = false
    @State private var showLogoutConfirmation = false

    // Message template
    @AppStorage("messageTemplate") private var messageTemplate = "{device} connected"

    var body: some View {
        NavigationStack {
            Form {
                // Auto-messaging toggle
                autoMessagingSection

                // Message template
                messageTemplateSection

                // User profile
                if AuthService.shared.isAuthenticated {
                    userProfileSection
                }

                // Contact management
                contactsSection

                // Message history
                messagesSection

                // Account actions
                if AuthService.shared.isAuthenticated {
                    accountSection
                }
            }
            .navigationTitle("Messaging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showContacts) {
                ContactListView()
            }
            .sheet(isPresented: $showMessageHistory) {
                MessageHistoryView()
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    Task { @MainActor in
                        AuthService.shared.logout()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }

    // MARK: - Auto-Messaging Section

    private var autoMessagingSection: some View {
        Section {
            Toggle("Auto-Send Messages", isOn: Binding(
                get: { bleManager.messagingEnabled },
                set: { bleManager.messagingEnabled = $0 }
            ))
        } header: {
            Text("Auto-Messaging")
        } footer: {
            Text("When enabled, messages will be sent to your selected contacts when ESP32 connects")
        }
    }

    // MARK: - Message Template Section

    private var messageTemplateSection: some View {
        Section {
            TextField("Message Template", text: $messageTemplate, axis: .vertical)
                .lineLimit(2...4)

            // Preview
            if !messageTemplate.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(previewMessage)
                        .font(.subheadline)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            // Reset button
            Button("Reset to Default") {
                messageTemplate = "{device} connected"
            }
            .font(.subheadline)
        } header: {
            Text("Message Template")
        } footer: {
            Text("Customize your message. Use {device} for device name, {time} for timestamp.\nExample: \"{device} is now online\" → \"Living Room ESP32 is now online\"")
        }
    }

    private var previewMessage: String {
        messageTemplate
            .replacingOccurrences(of: "{device}", with: "ESP32 Device")
            .replacingOccurrences(of: "{time}", with: Date().formatted(date: .omitted, time: .shortened))
    }

    // MARK: - User Profile Section

    private var userProfileSection: some View {
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
        } header: {
            Text("Account")
        }
    }

    // MARK: - Contacts Section

    private var contactsSection: some View {
        Section {
            Button {
                showContacts = true
            } label: {
                HStack {
                    Label("Manage Contacts", systemImage: "person.2")
                    Spacer()
                    if !contactService.contacts.isEmpty {
                        Text("\(contactService.selectedContactIds.count) selected")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text("Contacts")
        } footer: {
            if contactService.selectedContactIds.isEmpty {
                Text("Add and select contacts who will receive messages when your device connects")
            } else {
                Text("Messages will be sent to \(contactService.selectedContactIds.count) selected contact(s)")
            }
        }
    }

    // MARK: - Messages Section

    private var messagesSection: some View {
        Section {
            Button {
                showMessageHistory = true
            } label: {
                HStack {
                    Label("Message History", systemImage: "envelope")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text("History")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

#Preview {
    MessagingSettingsView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
