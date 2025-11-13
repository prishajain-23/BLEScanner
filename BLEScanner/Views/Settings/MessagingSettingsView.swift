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
    @State private var pushService = PushNotificationService.shared
    var bleManager: BLEManager

    @State private var showContacts = false
    @State private var showLogoutConfirmation = false
    @State private var isSendingTestMessage = false
    @State private var testMessageResult: String?

    // Message template
    @AppStorage("messageTemplate") private var messageTemplate = "I've been stopped by ICE on {date} at {time}.\nLocation: {location}\n\nFind me using the ICE locator at https://locator.ice.gov/odls\n\nMy A-number is ____.\nMy legal documents are at ____. Please get them and contact my lawyer ____.\n\nI entrust short-term guardianship of my children to ____. Please pick them up from school/daycare immediately and make any needed medical or legal decisions for them.\n\nMy next court date is ____.\nPlease notify my workplace at ____.\nMy medications are ____."

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

                // Test encryption
                if AuthService.shared.isAuthenticated {
                    testMessageSection
                }

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
            Text("When enabled, messages will be sent to your selected contacts when Medal of Freedom connects")
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

            // Sample templates
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Templates:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Button("Full ICE Encounter (Detailed)") {
                    messageTemplate = "I've been stopped by ICE on {date} at {time}.\nLocation: {location}\n\nFind me using the ICE locator at https://locator.ice.gov/odls\n\nMy A-number is ____.\nMy legal documents are at ____. Please get them and contact my lawyer ____.\n\nI entrust short-term guardianship of my children to ____. Please pick them up from school/daycare immediately and make any needed medical or legal decisions for them.\n\nMy next court date is ____.\nPlease notify my workplace at ____.\nMy medications are ____.\n\nPlease take care of my pets at ____.\nMy bank account information is with ____.\nMy rent/mortgage is due on ____."
                }
                .font(.caption)
                .buttonStyle(.borderless)

                Button("With Children & Documents") {
                    messageTemplate = "ICE stopped me on {date} at {time}.\nLocation: {location}\n\nMy kids need to be picked up - I'm giving temporary guardianship to ____. They can make medical and legal choices.\n\nMy legal papers are located at ____. Please contact my lawyer ____.\n\nFind me at https://locator.ice.gov/odls"
                }
                .font(.caption)
                .buttonStyle(.borderless)

                Button("With Documents Only") {
                    messageTemplate = "I've been detained by ICE - {date} at {time}.\nLocation: {location}\n\nI need an attorney. My important legal documents are located at ____. Please retrieve them and contact my lawyer _____.\n\nYou can find me using https://locator.ice.gov/odls"
                }
                .font(.caption)
                .buttonStyle(.borderless)

                Button("Brief Message") {
                    messageTemplate = "I've been stopped by ICE on {date} at {time}.\nLocation: {location}\n\nFind me: https://locator.ice.gov/odls"
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        } header: {
            Text("Message Template")
        } footer: {
            Text("Your message will be sent automatically when your Medal of Freedom connects. Use {date} for date, {time} for time, and {location} for GPS coordinates. Replace ____ with specific names and locations before an emergency.\n\nKnow Your Rights: You have the right to remain silent and request an attorney. Do not consent to searches. Make sure emergency contacts know they may need to care for your children.")
        }
    }

    private var previewMessage: String {
        let now = Date()
        return messageTemplate
            .replacingOccurrences(of: "{device}", with: "Medal of Freedom")
            .replacingOccurrences(of: "{date}", with: now.formatted(date: .abbreviated, time: .omitted))
            .replacingOccurrences(of: "{time}", with: now.formatted(date: .omitted, time: .shortened))
            .replacingOccurrences(of: "{location}", with: "Brooklyn, NY - https://maps.google.com/?q=40.748817,-73.985428")
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

    // MARK: - Test Message Section

    private var testMessageSection: some View {
        Section {
            Button {
                Task {
                    await regenerateKeys()
                }
            } label: {
                HStack {
                    Label("Regenerate Encryption Keys", systemImage: "key.fill")
                    Spacer()
                    if isSendingTestMessage {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(isSendingTestMessage)

            Button {
                Task {
                    await sendTestMessage()
                }
            } label: {
                HStack {
                    Label("Send Test Message", systemImage: "paperplane.fill")
                    Spacer()
                    if isSendingTestMessage {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(isSendingTestMessage || contactService.selectedContactIds.isEmpty)

            if let result = testMessageResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("✅") ? .green : .red)
            }
        } header: {
            Text("Testing")
        } footer: {
            if contactService.selectedContactIds.isEmpty {
                Text("Select at least one contact to send a test message")
            } else {
                Text("Send an encrypted test message to \(contactService.selectedContactIds.count) selected contact(s)")
            }
        }
    }

    private func regenerateKeys() async {
        isSendingTestMessage = true
        testMessageResult = nil

        do {
            // Force regenerate and upload keys
            try await CryptoKeyManager.shared.setupKeys()
            testMessageResult = "✅ Keys regenerated and uploaded!"
        } catch {
            testMessageResult = "❌ Failed to regenerate keys: \(error.localizedDescription)"
        }

        isSendingTestMessage = false

        // Clear result after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            testMessageResult = nil
        }
    }

    private func sendTestMessage() async {
        isSendingTestMessage = true
        testMessageResult = nil

        let selectedIds = contactService.selectedContactIds
        let testMessage = "🔐 Test encrypted message from Medal of Freedom"

        let success = await MessagingService.shared.sendMessage(
            toUserIds: selectedIds,
            message: testMessage,
            deviceName: "Test Device"
        )

        isSendingTestMessage = false
        testMessageResult = success ? "✅ Message sent successfully!" : "❌ Failed to send message"

        // Clear result after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            testMessageResult = nil
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
