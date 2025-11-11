//
//  CryptoEncryptionService.swift
//  BLEScanner
//
//  CryptoKit-based message encryption and decryption
//

import Foundation
import CryptoKit

class CryptoEncryptionService {

    // MARK: - Singleton

    static let shared = CryptoEncryptionService()

    // MARK: - Properties

    private let keyManager = CryptoKeyManager.shared

    private init() {}

    // MARK: - Encryption

    /// Encrypt a message for multiple recipients
    func encryptMessage(
        _ message: String,
        for userIds: [Int]
    ) async throws -> [(userId: Int, encryptedPayload: Data, senderRatchetKey: Data?, counter: Int?)] {

        var encryptedMessages: [(userId: Int, encryptedPayload: Data, senderRatchetKey: Data?, counter: Int?)] = []

        for userId in userIds {
            let encrypted = try await encryptMessageForUser(message, userId: userId)
            encryptedMessages.append(encrypted)
        }

        return encryptedMessages
    }

    /// Encrypt a message for a single user
    private func encryptMessageForUser(
        _ message: String,
        userId: Int
    ) async throws -> (userId: Int, encryptedPayload: Data, senderRatchetKey: Data?, counter: Int?) {

        // 1. Get our private key
        let _ = try keyManager.getIdentityKeyPair()

        // 2. Fetch recipient's public key
        let recipientPublicKey = try await keyManager.fetchPublicKey(for: userId)

        // 3. Generate ephemeral key pair (for perfect forward secrecy)
        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let ephemeralPublicKey = ephemeralPrivateKey.publicKey

        // 4. Perform ECDH key agreement with recipient's public key
        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)

        // 5. Derive symmetric key using HKDF
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("BLEScanner-E2EE".utf8),
            outputByteCount: 32
        )

        // 6. Encrypt the message with AES-GCM
        let messageData = Data(message.utf8)
        let sealedBox = try AES.GCM.seal(messageData, using: symmetricKey)

        // 7. Combine: ephemeralPublicKey + nonce + ciphertext + tag
        guard let combinedData = sealedBox.combined else {
            throw NSError(domain: "CryptoEncryptionService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create sealed box"
            ])
        }

        // Prepend ephemeral public key (32 bytes) to the encrypted data
        var encryptedPayload = ephemeralPublicKey.rawRepresentation
        encryptedPayload.append(combinedData)

        return (
            userId: userId,
            encryptedPayload: encryptedPayload,
            senderRatchetKey: ephemeralPublicKey.rawRepresentation,
            counter: nil
        )
    }

    // MARK: - Decryption

    /// Decrypt a message from a user
    func decryptMessage(
        encryptedPayload: Data,
        from userId: Int
    ) async throws -> String {

        // 1. Extract ephemeral public key (first 32 bytes)
        guard encryptedPayload.count > 32 else {
            throw NSError(domain: "CryptoEncryptionService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid encrypted payload"
            ])
        }

        let ephemeralPublicKeyData = encryptedPayload.prefix(32)
        let sealedBoxData = encryptedPayload.suffix(from: 32)

        // 2. Parse ephemeral public key
        let ephemeralPublicKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: ephemeralPublicKeyData
        )

        // 3. Get our private key
        let ourPrivateKey = try keyManager.getIdentityKeyPair()

        // 4. Perform ECDH key agreement with sender's ephemeral key
        let sharedSecret = try ourPrivateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)

        // 5. Derive symmetric key using HKDF (same parameters as encryption)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("BLEScanner-E2EE".utf8),
            outputByteCount: 32
        )

        // 6. Decrypt with AES-GCM
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)

        // 7. Convert to string
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw NSError(domain: "CryptoEncryptionService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode decrypted message"
            ])
        }

        return decryptedString
    }
}
