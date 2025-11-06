//
//  MessageHistoryView.swift
//  BLEScanner
//
//  View message history (sent and received)
//

import SwiftUI

struct MessageHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && messages.isEmpty {
                    ProgressView("Loading messages...")
                } else if let error = errorMessage {
                    errorView(error)
                } else if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }
            }
            .navigationTitle("Message History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadMessages()
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        List {
            Section {
                ForEach(messages) { message in
                    messageRow(message)
                }
            } header: {
                Text("Recent Messages")
            } footer: {
                Text("Showing last \(messages.count) messages")
            }
        }
        .refreshable {
            await loadMessages()
        }
    }

    private func messageRow(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Username and timestamp
            HStack {
                Label {
                    Text(message.isSent ? "To: \(message.fromUsername)" : "From: \(message.fromUsername)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: message.isSent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(message.isSent ? .blue : .green)
                }

                Spacer()

                Text(message.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Device name (if available)
            if let deviceName = message.deviceName {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(deviceName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Message text
            Text(message.messageText)
                .font(.body)
                .padding(.vertical, 4)

            // Read status
            if !message.isSent {
                HStack(spacing: 4) {
                    Image(systemName: message.read == true ? "envelope.open.fill" : "envelope.fill")
                        .font(.caption2)

                    Text(message.read == true ? "Read" : "Unread")
                        .font(.caption2)
                }
                .foregroundStyle(message.read == true ? .secondary : .blue)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Messages", systemImage: "envelope.open")
        } description: {
            Text("Messages you send and receive will appear here")
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error)
        } actions: {
            Button("Retry") {
                Task {
                    await loadMessages()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func loadMessages() async {
        isLoading = true
        errorMessage = nil

        do {
            messages = await MessagingService.shared.fetchMessageHistory(limit: 50)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    MessageHistoryView()
}
