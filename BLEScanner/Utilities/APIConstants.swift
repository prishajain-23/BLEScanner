//
//  APIConstants.swift
//  BLEScanner
//
//  Created for BLEScanner Messaging System
//

import Foundation

struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:3000/api"
    #else
    static let baseURL = "https://your-domain.com/api" // Update when deploying
    #endif

    static let timeout: TimeInterval = 30
}

struct APIEndpoints {
    // Authentication
    static let register = "/auth/register"
    static let login = "/auth/login"

    // Users
    static let userSearch = "/users/search"
    static let userProfile = "/users/me"

    // Contacts
    static let contacts = "/contacts"
    static let addContact = "/contacts/add"
    static func removeContact(_ id: Int) -> String { "/contacts/\(id)" }

    // Messages
    static let sendMessage = "/messages/send"
    static let messageHistory = "/messages/history"
    static func markMessageRead(_ id: Int) -> String { "/messages/\(id)/read" }

    // Devices
    static let registerPush = "/devices/register-push"
    static let unregisterPush = "/devices/unregister-push"
}

struct AppConfig {
    static let messageHistoryLimit = 50
    static let maxRetryAttempts = 3
    static let offlineQueueLimit = 100
}
