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
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var hasMoreMessages = true

    private let pageSize = 20
    private var currentOffset: Int {
        messages.count
    }

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
                setupNotificationObserver()
            }
        }
    }

    // MARK: - Notification Observer

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NewMessageReceived"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await refreshMessages()
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        List {
            Section {
                ForEach(messages) { message in
                    messageRow(message)
                        .onAppear {
                            // Load more when scrolling near the end
                            if message.id == messages.last?.id {
                                Task {
                                    await loadMoreMessages()
                                }
                            }
                        }
                }

                // Loading indicator at bottom
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading more...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Recent Messages")
            } footer: {
                if hasMoreMessages && !isLoadingMore {
                    Text("Scroll to load more")
                } else if !hasMoreMessages {
                    Text("All messages loaded")
                }
            }
        }
        .refreshable {
            await refreshMessages()
        }
    }

    private func messageRow(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Direction and timestamp
            HStack {
                Label {
                    if message.isSent {
                        if let recipients = message.toUsernames, !recipients.isEmpty {
                            Text("To: \(recipients.joined(separator: ", "))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } else {
                            Text("Sent")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("From: \(message.fromUsername)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
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
                .foregroundStyle(message.read == true ? Color.secondary : Color.blue)
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

        let fetchedMessages = await MessagingService.shared.fetchMessageHistory(limit: pageSize, offset: 0)

        messages = fetchedMessages
        hasMoreMessages = fetchedMessages.count == pageSize
        isLoading = false
    }

    private func loadMoreMessages() async {
        // Don't load if already loading or no more messages
        guard !isLoadingMore && !isLoading && hasMoreMessages else { return }

        isLoadingMore = true

        let newMessages = await MessagingService.shared.fetchMessageHistory(limit: pageSize, offset: currentOffset)

        // Append new messages (avoiding duplicates)
        let uniqueNewMessages = newMessages.filter { newMsg in
            !messages.contains { $0.id == newMsg.id }
        }
        messages.append(contentsOf: uniqueNewMessages)

        hasMoreMessages = newMessages.count == pageSize
        isLoadingMore = false
    }

    private func refreshMessages() async {
        // Reset and load from scratch
        messages = []
        hasMoreMessages = true
        await loadMessages()
    }
}

#Preview {
    MessageHistoryView()
}
