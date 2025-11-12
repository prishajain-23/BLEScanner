//
//  AuthService.swift
//  BLEScanner
//
//  Authentication service for login/register
//

import Foundation
import Observation

@MainActor
@Observable
class AuthService {
    static let shared = AuthService()

    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    private init() {
        // Check if user is already logged in
        if KeychainHelper.shared.getToken() != nil,
           let username = KeychainHelper.shared.getUsername() {
            isAuthenticated = true
            // Create a placeholder user object
            currentUser = User(id: 0, username: username, createdAt: nil, contactCount: nil)
        }
    }

    // MARK: - Register

    func register(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            struct RegisterRequest: Encodable {
                let username: String
                let password: String
            }

            let request = RegisterRequest(username: username, password: password)
            let response: AuthResponse = try await APIClient.shared.post(
                endpoint: APIEndpoints.register,
                body: request,
                requiresAuth: false
            )

            if response.success, let user = response.user, let token = response.token {
                // Save credentials
                _ = KeychainHelper.shared.saveToken(token)
                _ = KeychainHelper.shared.saveUsername(user.username)

                // Update state
                currentUser = user
                isAuthenticated = true

                // Setup encryption keys for new user
                Task {
                    do {
                        try await CryptoKeyManager.shared.setupKeys()
                        print("✅ Encryption keys set up for new user")
                    } catch {
                        print("⚠️ Failed to setup encryption keys: \(error.localizedDescription)")
                    }
                }

                // Notify observers (for push notification registration)
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
            } else {
                errorMessage = response.error ?? "Registration failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Login

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            struct LoginRequest: Encodable {
                let username: String
                let password: String
            }

            let request = LoginRequest(username: username, password: password)
            let response: AuthResponse = try await APIClient.shared.post(
                endpoint: APIEndpoints.login,
                body: request,
                requiresAuth: false
            )

            if response.success, let user = response.user, let token = response.token {
                // Save credentials
                _ = KeychainHelper.shared.saveToken(token)
                _ = KeychainHelper.shared.saveUsername(user.username)

                // Update state
                currentUser = user
                isAuthenticated = true

                // Setup encryption keys (always upload to ensure server has them)
                Task {
                    do {
                        try await CryptoKeyManager.shared.setupKeys()
                        print("✅ Encryption keys set up on login")
                    } catch {
                        print("⚠️ Failed to setup encryption keys: \(error.localizedDescription)")
                    }
                }

                // Notify observers (for push notification registration)
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
            } else {
                errorMessage = response.error ?? "Login failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Logout

    func logout() {
        // Unregister push token
        Task {
            await PushNotificationService.shared.unregisterFromBackend()
        }

        _ = KeychainHelper.shared.clearAll()
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Get Profile

    func fetchUserProfile() async {
        do {
            struct ProfileResponse: Codable {
                let success: Bool
                let user: User?
            }

            let response: ProfileResponse = try await APIClient.shared.get(
                endpoint: APIEndpoints.userProfile,
                requiresAuth: true
            )

            if response.success, let user = response.user {
                currentUser = user
            }
        } catch {
            print("Failed to fetch profile: \(error.localizedDescription)")
        }
    }
}
