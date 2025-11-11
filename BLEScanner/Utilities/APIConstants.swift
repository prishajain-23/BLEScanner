//
//  APIConstants.swift
//  BLEScanner
//
//  Created for BLEScanner Messaging System
//

import Foundation

struct APIConfig {
    // Production server deployed at 142.93.184.210
    static let baseURL = "http://142.93.184.210/api"
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
    static let sendEncryptedMessage = "/messages/send-encrypted"
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
