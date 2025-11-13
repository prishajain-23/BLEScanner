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
    private let encryptionService = CryptoEncryptionService.shared
    private let keyManager = CryptoKeyManager.shared

    private init() {}

    // MARK: - Send Message

    /// Send a message to specified users (encrypted)
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

        print("📤 Encrypting and sending message to \(toUserIds.count) recipient(s)")

        do {
            // Check if user has encryption keys set up
            if !keyManager.hasKeys() {
                print("⚠️ No encryption keys found, setting up...")
                try await keyManager.setupKeys()
            } else {
                print("🔐 Encryption keys found")
            }

            // Encrypt the message for each recipient
            print("🔒 Starting encryption for \(toUserIds.count) recipient(s)...")
            let encryptedMessages = try await encryptionService.encryptMessage(message, for: toUserIds)
            print("✅ Encryption complete")

            // Convert to API format
            let messagesPayload = encryptedMessages.map { encrypted in
                EncryptedMessagePayload(
                    toUserId: encrypted.userId,
                    encryptedPayload: encrypted.encryptedPayload.base64EncodedString(),
                    senderRatchetKey: encrypted.senderRatchetKey?.base64EncodedString(),
                    counter: encrypted.counter
                )
            }

            let payload = SendEncryptedMessageRequest(
                messages: messagesPayload,
                deviceName: deviceName ?? "Unknown Device"
            )

            print("🌐 Sending to backend: \(APIEndpoints.sendEncryptedMessage)")
            // Send encrypted messages to backend
            let response: MessageSendResponse = try await apiClient.post(
                endpoint: APIEndpoints.sendEncryptedMessage,
                body: payload,
                requiresAuth: true
            )

            if response.success {
                print("✅ Encrypted message sent successfully")
                print("📊 Backend response: \(response)")
                return true
            } else {
                print("❌ Failed to send encrypted message: \(response.error ?? "Unknown error")")
                return false
            }
        } catch {
            print("❌ Error sending encrypted message: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            return false
        }
    }

    /// Send a connection message (convenience method for BLE connections)
    /// - Parameters:
    ///   - deviceName: Name of the BLE device
    ///   - contactIds: Array of contact IDs to send to
    func sendConnectionMessage(deviceName: String, contactIds: [Int]) async {
        print("📱 sendConnectionMessage called - deviceName: \(deviceName), contactIds: \(contactIds)")

        // Get message template from UserDefaults, or use default
        let template = UserDefaults.standard.string(forKey: "messageTemplate") ?? "{device} connected"
        print("📝 Message template: \(template)")

        // Get current location
        let location = await LocationService.shared.getCurrentLocation()
        print("📍 Location: \(location)")

        // Replace template variables
        let now = Date()
        let message = template
            .replacingOccurrences(of: "{device}", with: deviceName)
            .replacingOccurrences(of: "{date}", with: now.formatted(date: .abbreviated, time: .omitted))
            .replacingOccurrences(of: "{time}", with: now.formatted(date: .omitted, time: .shortened))
            .replacingOccurrences(of: "{location}", with: location)

        print("📧 Final message: \(message)")

        let success = await sendMessage(toUserIds: contactIds, message: message, deviceName: deviceName)
        print("📊 Send result: \(success ? "SUCCESS" : "FAILED")")
    }

    // MARK: - Message History

    /// Fetch message history from backend (with pagination support and decryption)
    /// - Parameters:
    ///   - limit: Maximum number of messages to fetch (default 20)
    ///   - offset: Number of messages to skip (for pagination, default 0)
    /// - Returns: Array of messages (decrypted)
    func fetchMessageHistory(limit: Int = 20, offset: Int = 0) async -> [Message] {
        guard await AuthService.shared.isAuthenticated else {
            print("⚠️ MessagingService: User not authenticated")
            return []
        }

        let endpoint = APIEndpoints.messageHistory + "?limit=\(limit)&offset=\(offset)"

        do {
            let response: MessageHistoryResponse = try await apiClient.get(endpoint: endpoint, requiresAuth: true)

            if response.success, let messages = response.messages {
                print("✅ Fetched \(messages.count) messages (offset: \(offset))")

                // Decrypt encrypted messages
                var decryptedMessages: [Message] = []

                for message in messages {
                    var msg = message

                    // Only decrypt received encrypted messages
                    if !message.isSent && message.encryptionVersion == 1 {
                        do {
                            guard let encryptedPayload = message.encryptedPayload,
                                  let payloadData = Data(base64Encoded: encryptedPayload) else {
                                msg.messageText = "[Unable to decrypt]"
                                decryptedMessages.append(msg)
                                continue
                            }

                            let decrypted = try await encryptionService.decryptMessage(
                                encryptedPayload: payloadData,
                                from: message.fromUserId
                            )

                            msg.messageText = decrypted
                            print("🔓 Decrypted message from user \(message.fromUserId)")
                        } catch {
                            print("❌ Failed to decrypt message: \(error.localizedDescription)")
                            msg.messageText = "[Unable to decrypt message]"
                        }
                    }

                    decryptedMessages.append(msg)
                }

                return decryptedMessages
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

private struct EncryptedMessagePayload: Codable {
    let toUserId: Int
    let encryptedPayload: String
    let senderRatchetKey: String?
    let counter: Int?

    enum CodingKeys: String, CodingKey {
        case toUserId = "to_user_id"
        case encryptedPayload = "encrypted_payload"
        case senderRatchetKey = "sender_ratchet_key"
        case counter
    }
}

private struct SendEncryptedMessageRequest: Codable {
    let messages: [EncryptedMessagePayload]
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case messages
        case deviceName = "device_name"
    }
}

private struct EmptyRequest: Codable {}
