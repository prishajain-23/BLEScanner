//
//  MessagingModels.swift
//  BLEScanner
//
//  Data models for messaging system
//

import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let createdAt: Date?
    let contactCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, username
        case createdAt = "created_at"
        case contactCount = "contact_count"
    }
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let success: Bool
    let user: User?
    let token: String?
    let error: String?
}

// MARK: - Contact
struct Contact: Codable, Identifiable {
    let id: Int
    let username: String
    let nickname: String?
    let addedAt: Date?
    var isSelectedForMessaging: Bool? // Local-only property for UI state

    enum CodingKeys: String, CodingKey {
        case id, username, nickname
        case addedAt = "added_at"
        // isSelectedForMessaging is not encoded/decoded (local state only)
    }
}

// MARK: - Message
struct Message: Codable, Identifiable {
    let id: Int
    let fromUserId: Int
    let fromUsername: String
    let messageText: String
    let deviceName: String?
    let createdAt: Date
    let isSent: Bool
    let read: Bool?
    let readAt: Date?
    let toUsernames: [String]? // Recipients (for sent messages)

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case fromUsername = "from_username"
        case messageText = "message_text"
        case deviceName = "device_name"
        case createdAt = "created_at"
        case isSent = "is_sent"
        case read
        case readAt = "read_at"
        case toUsernames = "to_usernames"
    }
}

// MARK: - API Responses
struct ContactsResponse: Codable {
    let success: Bool
    let contacts: [Contact]?
    let error: String?
}

struct UserSearchResponse: Codable {
    let success: Bool
    let users: [User]?
    let error: String?
}

struct MessageHistoryResponse: Codable {
    let success: Bool
    let messages: [Message]?
    let total: Int?
    let limit: Int?
    let offset: Int?
    let error: String?
}

struct MessageSendResponse: Codable {
    let success: Bool
    let message: SentMessage?
    let pushSent: Bool?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success, message, error
        case pushSent = "push_sent"
    }
}

struct SentMessage: Codable {
    let id: Int
    let fromUserId: Int
    let messageText: String
    let deviceName: String?
    let createdAt: Date
    let recipients: [Int]

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case messageText = "message_text"
        case deviceName = "device_name"
        case createdAt = "created_at"
        case recipients
    }
}

struct GenericResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
