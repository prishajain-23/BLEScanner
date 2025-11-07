//
//  KeychainHelper.swift
//  BLEScanner
//
//  Securely store JWT tokens in iOS Keychain
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.prishajain.blescanner"
    private let jwtTokenKey = "jwt_token"
    private let usernameKey = "username"

    private init() {}

    // MARK: - JWT Token

    func saveToken(_ token: String) -> Bool {
        return save(key: jwtTokenKey, value: token)
    }

    func getToken() -> String? {
        return get(key: jwtTokenKey)
    }

    func deleteToken() -> Bool {
        return delete(key: jwtTokenKey)
    }

    // MARK: - Username

    func saveUsername(_ username: String) -> Bool {
        return save(key: usernameKey, value: username)
    }

    func getUsername() -> String? {
        return get(key: usernameKey)
    }

    func deleteUsername() -> Bool {
        return delete(key: usernameKey)
    }

    // MARK: - Clear All

    func clearAll() -> Bool {
        let tokenDeleted = deleteToken()
        let usernameDeleted = deleteUsername()
        return tokenDeleted && usernameDeleted
    }

    // MARK: - Private Keychain Operations

    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing value
        _ = delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
