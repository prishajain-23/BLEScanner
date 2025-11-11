//
//  PushNotificationService.swift
//  BLEScanner
//
//  Handles APNs push notification device token registration and management
//

import Foundation
import UIKit
import UserNotifications

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var isRegistered = false
    @Published var deviceToken: String?

    private let apiClient = APIClient.shared
    private var authObserver: NSObjectProtocol?

    private override init() {
        super.init()

        // Load cached token
        if let savedToken = UserDefaults.standard.string(forKey: "deviceToken") {
            deviceToken = savedToken
            isRegistered = true
        }

        // Re-register when user logs in
        setupAuthObserver()
    }

    deinit {
        if let observer = authObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup

    private func setupAuthObserver() {
        authObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidLogin"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.registerIfNeeded()
            }
        }
    }

    // MARK: - Request Permissions

    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "✅ Push notification permissions granted" : "⚠️ Push notification permissions denied")
            return granted
        } catch {
            print("❌ Error requesting push permissions: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Register for Remote Notifications

    func registerForRemoteNotifications() {
        Task { @MainActor in
            let granted = await requestPermissions()

            guard granted else {
                print("⚠️ Cannot register for remote notifications - permission denied")
                return
            }

            // Register with APNs
            UIApplication.shared.registerForRemoteNotifications()
            print("📱 Registering for remote notifications...")
        }
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        // Convert token to hex string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        print("✅ APNs device token received: \(tokenString)")

        self.deviceToken = tokenString
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")

        // Register with backend
        Task {
            await registerWithBackend(deviceToken: tokenString)
        }
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        isRegistered = false
    }

    // MARK: - Backend Registration

    private func registerWithBackend(deviceToken: String) async {
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ User not authenticated, skipping backend registration")
            return
        }

        struct RegisterPushRequest: Codable {
            let deviceToken: String
            let platform: String

            enum CodingKeys: String, CodingKey {
                case deviceToken = "device_token"
                case platform
            }
        }

        let request = RegisterPushRequest(
            deviceToken: deviceToken,
            platform: "ios"
        )

        print("📤 Registering device token with backend...")

        do {
            let response: GenericResponse = try await apiClient.post(
                endpoint: APIEndpoints.registerPush,
                body: request,
                requiresAuth: true
            )

            if response.success {
                isRegistered = true
                print("✅ Device token registered with backend")
            } else {
                print("❌ Failed to register device token: \(response.error ?? "Unknown error")")
            }
        } catch {
            print("❌ Error registering device token: \(error.localizedDescription)")
        }
    }

    func registerIfNeeded() async {
        guard let token = deviceToken else {
            print("⚠️ No device token available")
            return
        }

        await registerWithBackend(deviceToken: token)
    }

    // MARK: - Unregister

    func unregisterFromBackend() async {
        guard AuthService.shared.isAuthenticated else { return }

        print("📤 Unregistering device token from backend...")

        do {
            struct EmptyRequest: Codable {}
            let response: GenericResponse = try await apiClient.delete(
                endpoint: APIEndpoints.unregisterPush,
                requiresAuth: true
            )

            if response.success {
                isRegistered = false
                deviceToken = nil
                UserDefaults.standard.removeObject(forKey: "deviceToken")
                print("✅ Device token unregistered from backend")
            } else {
                print("❌ Failed to unregister device token: \(response.error ?? "Unknown error")")
            }
        } catch {
            print("❌ Error unregistering device token: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Remote Notification

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("📨 Received remote notification: \(userInfo)")

        // Extract message data
        guard let aps = userInfo["aps"] as? [String: Any] else {
            print("⚠️ No aps data in notification")
            return
        }

        // Show alert if needed (for foreground notifications)
        if let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            print("📬 Message: \(title) - \(body)")
        }

        // Refresh message history if app is active
        // This will be handled by NotificationCenter observers in views
        NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
    }
}
