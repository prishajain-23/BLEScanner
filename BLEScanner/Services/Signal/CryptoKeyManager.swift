//
//  CryptoKeyManager.swift
//  BLEScanner
//
//  CryptoKit-based key management for E2EE messaging
//

import Foundation
import CryptoKit

class CryptoKeyManager {

    // MARK: - Singleton

    static let shared = CryptoKeyManager()

    // MARK: - Properties

    private let apiClient = APIClient.shared
    private let keychainHelper = KeychainHelper.shared

    private let identityKeyKey = "cryptokit_identity_private_key"
    private let registrationIdKey = "cryptokit_registration_id"

    private init() {}

    // MARK: - Identity Key Management

    /// Get or generate the user's identity key pair
    func getIdentityKeyPair() throws -> Curve25519.KeyAgreement.PrivateKey {
        // Try to load existing key from Keychain
        if let keyData = keychainHelper.load(key: identityKeyKey) {
            return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
        }

        // Generate new key pair
        let privateKey = Curve25519.KeyAgreement.PrivateKey()

        // Store in Keychain
        keychainHelper.save(data: privateKey.rawRepresentation, key: identityKeyKey)

        return privateKey
    }

    /// Get the local registration ID
    func getRegistrationId() -> UInt32 {
        let stored = UserDefaults.standard.integer(forKey: registrationIdKey)
        if stored > 0 {
            return UInt32(stored)
        }

        // Generate random registration ID (1-16383)
        let regId = UInt32.random(in: 1...16383)
        UserDefaults.standard.set(Int(regId), forKey: registrationIdKey)
        return regId
    }

    /// Check if keys are set up
    func hasKeys() -> Bool {
        return keychainHelper.load(key: identityKeyKey) != nil
    }

    // MARK: - Key Upload

    /// Generate and upload keys to backend
    func setupKeys() async throws {
        print("🔐 Generating CryptoKit keys...")

        let privateKey = try getIdentityKeyPair()
        let publicKey = privateKey.publicKey
        let registrationId = getRegistrationId()

        print("📤 Uploading public key to backend...")

        // Upload public key to backend
        do {
            try await uploadPublicKey(publicKey: publicKey, registrationId: registrationId)
            print("✅ Keys uploaded to backend successfully")
        } catch {
            print("❌ Failed to upload keys: \(error.localizedDescription)")
            throw error
        }
    }

    /// Upload public key to backend
    private func uploadPublicKey(
        publicKey: Curve25519.KeyAgreement.PublicKey,
        registrationId: UInt32
    ) async throws {

        let publicKeyData = publicKey.rawRepresentation

        print("🔑 Identity key size: \(publicKeyData.count) bytes")

        struct SignedPrekeyPayload: Codable {
            let keyId: Int
            let publicKey: String
            let signature: String
        }

        struct OneTimePrekeyPayload: Codable {
            let keyId: Int
            let publicKey: String
        }

        struct KeyUploadPayload: Codable {
            let identityKey: String
            let registrationId: Int
            let signedPrekey: SignedPrekeyPayload
            let oneTimePrekeys: [OneTimePrekeyPayload]
        }

        // Generate a dummy one-time prekey (CryptoKit doesn't need many)
        let dummyPrekey = OneTimePrekeyPayload(
            keyId: 1,
            publicKey: publicKeyData.base64EncodedString()
        )

        // Create signed prekey with dummy signature (we're not using real signatures for CryptoKit)
        // Use a valid base64-safe dummy signature (all zeros would create null bytes which break JSON)
        let dummySignatureString = String(repeating: "A", count: 64)
        let dummySignature = Data(dummySignatureString.utf8)

        let signedPrekey = SignedPrekeyPayload(
            keyId: 1,
            publicKey: publicKeyData.base64EncodedString(),
            signature: dummySignature.base64EncodedString()
        )

        print("🔑 Signed prekey - keyId: \(signedPrekey.keyId), publicKey length: \(publicKeyData.count), signature length: \(dummySignature.count)")

        let payload = KeyUploadPayload(
            identityKey: publicKeyData.base64EncodedString(),
            registrationId: Int(registrationId),
            signedPrekey: signedPrekey,
            oneTimePrekeys: [dummyPrekey] // At least one prekey required
        )

        struct UploadResponse: Codable {
            let success: Bool
            let message: String?
        }

        let response: UploadResponse = try await apiClient.post(
            endpoint: "/keys/upload",
            body: payload,
            requiresAuth: true
        )

        print("📥 Upload response - success: \(response.success), message: \(response.message ?? "nil")")

        guard response.success else {
            throw NSError(domain: "CryptoKeyManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.message ?? "Failed to upload keys"
            ])
        }
    }

    // MARK: - Fetch Remote Public Keys

    /// Fetch public key for a user
    func fetchPublicKey(for userId: Int) async throws -> Curve25519.KeyAgreement.PublicKey {
        struct BundleResponse: Codable {
            let identityKey: String
            let registrationId: Int
            let signedPrekey: SignedPrekeyResponse

            struct SignedPrekeyResponse: Codable {
                let keyId: Int
                let publicKey: String
                let signature: String
            }
        }

        let response: BundleResponse = try await apiClient.get(
            endpoint: "/keys/bundle/\(userId)",
            requiresAuth: true
        )

        guard let publicKeyData = Data(base64Encoded: response.identityKey) else {
            throw NSError(domain: "CryptoKeyManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode public key"
            ])
        }

        return try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
    }
}
