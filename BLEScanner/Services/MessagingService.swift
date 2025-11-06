//
//  MessagingService.swift
//  BLEScanner
//
//  Handles sending messages to backend API
//

import Foundation

@Observable
class MessagingService {
    static let shared = MessagingService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Send Message

    /// Send a message to specified users
    /// - Parameters:
    ///   - toUserIds: Array of recipient user IDs
    ///   - message: Message text to send
    ///   - deviceName: Name of the BLE device that triggered the message
    /// - Returns: Success boolean
    @discardableResult
    func sendMessage(toUserIds: [Int], message: String, deviceName: String?) async -> Bool {
        guard !toUserIds.isEmpty else {
            print("⚠️ MessagingService: No recipients specified")
            return false
        }

        guard await AuthService.shared.isAuthenticated else {
            print("⚠️ MessagingService: User not authenticated")
            return false
        }

        let endpoint = APIEndpoints.sendMessage

        let payload = SendMessageRequest(
            toUserIds: toUserIds,
            message: message,
            deviceName: deviceName ?? "Unknown Device"
        )

        print("📤 Sending message to \(toUserIds.count) recipient(s): \"\(message)\"")

        do {
            let response: MessageSendResponse = try await apiClient.post(endpoint: endpoint, body: payload, requiresAuth: true)

            if response.success, let message = response.message {
                print("✅ Message sent successfully (ID: \(message.id))")
                return true
            } else {
                print("❌ Failed to send message: \(response.error ?? "Unknown error")")
                return false
            }
        } catch {
            print("❌ Error sending message: \(error.localizedDescription)")
            return false
        }
    }

    /// Send a connection message (convenience method for BLE connections)
    /// - Parameters:
    ///   - deviceName: Name of the BLE device
    ///   - contactIds: Array of contact IDs to send to
    func sendConnectionMessage(deviceName: String, contactIds: [Int]) async {
        // Get message template from UserDefaults, or use default
        let template = UserDefaults.standard.string(forKey: "messageTemplate") ?? "{device} connected"

        // Replace template variables
        let message = template
            .replacingOccurrences(of: "{device}", with: deviceName)
            .replacingOccurrences(of: "{time}", with: Date().formatted(date: .omitted, time: .shortened))

        await sendMessage(toUserIds: contactIds, message: message, deviceName: deviceName)
    }

    // MARK: - Message History

    /// Fetch message history from backend
    /// - Parameter limit: Maximum number of messages to fetch
    /// - Returns: Array of messages
    func fetchMessageHistory(limit: Int = 50) async -> [Message] {
        guard await AuthService.shared.isAuthenticated else {
            print("⚠️ MessagingService: User not authenticated")
            return []
        }

        let endpoint = APIEndpoints.messageHistory + "?limit=\(limit)"

        do {
            let response: MessageHistoryResponse = try await apiClient.get(endpoint: endpoint, requiresAuth: true)

            if response.success, let messages = response.messages {
                print("✅ Fetched \(messages.count) messages")
                return messages
            } else {
                print("❌ Failed to fetch message history")
                return []
            }
        } catch {
            print("❌ Error fetching message history: \(error.localizedDescription)")
            return []
        }
    }

    /// Mark a message as read
    /// - Parameter messageId: ID of the message to mark as read
    func markMessageAsRead(messageId: Int) async {
        guard await AuthService.shared.isAuthenticated else { return }

        let endpoint = APIEndpoints.markMessageRead(messageId)

        do {
            let response: GenericResponse = try await apiClient.post(endpoint: endpoint, body: EmptyRequest(), requiresAuth: true)

            if response.success {
                print("✅ Message \(messageId) marked as read")
            }
        } catch {
            print("❌ Error marking message as read: \(error.localizedDescription)")
        }
    }
}

// MARK: - Request Models

private struct SendMessageRequest: Codable {
    let toUserIds: [Int]
    let message: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case toUserIds = "to_user_ids"
        case message
        case deviceName = "device_name"
    }
}

private struct EmptyRequest: Codable {}
