//
//  MessagesHelpView.swift
//  BLEScanner
//
//  Help and instructions for the Messages tab
//

import SwiftUI

struct MessagesHelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        Text("Messages & Contacts")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Learn how to send messages and manage contacts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Auto-Messaging Overview
                    HelpSection(
                        icon: "bolt.fill",
                        iconColor: .yellow,
                        title: "Auto-Messaging"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When enabled, messages are automatically sent to your selected contacts whenever your Medal of Freedom connects.")
                                .font(.callout)

                            Text("How it works:")
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            HelpStep(number: 1, text: "Your Medal of Freedom connects via Bluetooth")
                            HelpStep(number: 2, text: "BLEScanner encrypts and sends your message")
                            HelpStep(number: 3, text: "Selected contacts receive push notifications")
                            HelpStep(number: 4, text: "Messages appear in their Message History")

                            Text("Enable auto-messaging in Settings → Messaging.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Adding Contacts
                    HelpSection(
                        icon: "person.badge.plus.fill",
                        iconColor: .green,
                        title: "Adding Contacts"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To add contacts who will receive your messages:")
                                .fontWeight(.medium)

                            HelpStep(number: 1, text: "Switch to the \"Contacts\" segment")
                            HelpStep(number: 2, text: "Tap the + button in the top right")
                            HelpStep(number: 3, text: "Search for a user by their username")
                            HelpStep(number: 4, text: "Tap \"Add\" next to their name")

                            Text("After adding, tap the contact to select/deselect them for messaging. Only selected contacts will receive your auto-messages.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Message History
                    HelpSection(
                        icon: "clock.arrow.circlepath",
                        iconColor: .purple,
                        title: "Message History"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The History tab shows all messages you've sent and received:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Sent messages show recipients and device name")
                            BulletPoint(text: "Received messages show sender and timestamp")
                            BulletPoint(text: "Pull down to refresh for new messages")
                            BulletPoint(text: "Messages are end-to-end encrypted")

                            Text("Messages are stored on the server for 30 days, then automatically deleted.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Message Templates
                    HelpSection(
                        icon: "text.bubble.fill",
                        iconColor: .blue,
                        title: "Customizing Messages"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personalize the message sent to contacts:")
                                .fontWeight(.medium)

                            HelpStep(number: 1, text: "Go to Settings → Messaging Settings")
                            HelpStep(number: 2, text: "Edit the \"Message Template\" field")
                            HelpStep(number: 3, text: "Use {device} for device name, {time} for timestamp")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Examples:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.top, 4)

                                TemplateExample(
                                    template: "{device} connected",
                                    result: "Living Room Medal of Freedom connected"
                                )

                                TemplateExample(
                                    template: "I'm home! {device} at {time}",
                                    result: "I'm home! Front Door Medal of Freedom at 3:45 PM"
                                )
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Device Registration Required
                    HelpSection(
                        icon: "antenna.radiowaves.left.and.right",
                        iconColor: .orange,
                        title: "Device Registration Required"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Before messages can be sent automatically:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Register your Medal of Freedom in the Connections tab")
                            BulletPoint(text: "Add at least one contact")
                            BulletPoint(text: "Enable auto-messaging in Settings")
                            BulletPoint(text: "Enable push notifications to receive messages")

                            Text("See Connections tab help (? icon) for device registration instructions.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Managing Contacts
                    HelpSection(
                        icon: "person.2.fill",
                        iconColor: .indigo,
                        title: "Managing Contacts"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("You can manage your contacts at any time:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Tap a contact to select/deselect for messaging")
                            BulletPoint(text: "Tap the trash icon to remove a contact")
                            BulletPoint(text: "Pull down to refresh your contacts list")

                            Text("Only contacts with a checkmark will receive your auto-messages. You can change selections anytime.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Messages Help")
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

// MARK: - Template Example View

struct TemplateExample: View {
    let template: String
    let result: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Template:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(template)
                    .font(.caption2)
                    .fontDesign(.monospaced)
            }

            HStack {
                Text("Result:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(result)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
}

#Preview {
    MessagesHelpView()
}
