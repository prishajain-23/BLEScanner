//
//  NotificationManager.swift
//  BLEScanner
//
//  Handles all notification-related functionality
//

import Foundation
import UserNotifications

@Observable
class NotificationManager {
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: UserDefaultsKeys.sendNotificationOnConnect)
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()

    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.sendNotificationOnConnect)
        requestPermissions()
    }

    // MARK: - Permissions
    func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("⚠️ Notification permissions denied")
                }
            }
        }
    }

    // MARK: - Send Notifications
    func sendConnectionNotification(deviceName: String) {
        print("🔔 sendConnectionNotification called for: \(deviceName)")
        print("🔔 notificationsEnabled: \(notificationsEnabled)")

        guard notificationsEnabled else {
            print("⚠️ Notifications disabled, skipping")
            return
        }

        // Check authorization status
        notificationCenter.getNotificationSettings { settings in
            print("🔔 Authorization status: \(settings.authorizationStatus.rawValue)")
            print("🔔 Alert setting: \(settings.alertSetting.rawValue)")

            guard settings.authorizationStatus == .authorized else {
                print("❌ Notifications not authorized")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "MOF Connected"
            content.body = "\(deviceName) is now connected"
            content.sound = .default

            // Category identifier for Shortcuts automation
            content.categoryIdentifier = "Medal of Freedom_CONNECTED"
            content.threadIdentifier = "ble-connection"

            // Custom data accessible in Shortcuts
            content.userInfo = [
                "deviceName": deviceName,
                "eventType": "Medal of FreedomConnected",
                "timestamp": Date().timeIntervalSince1970
            ]

            // Deliver immediately
            let request = UNNotificationRequest(
                identifier: "Medal of Freedom-connection-\(UUID().uuidString)",
                content: content,
                trigger: nil
            )

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Notification error: \(error.localizedDescription)")
                } else {
                    print("✅ Notification successfully added to queue for \(deviceName)")
                }
            }
        }
    }

    func sendDisconnectionNotification(deviceName: String) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Medal of Freedom Disconnected"
        content.body = "\(deviceName) has disconnected"
        content.sound = .default

        content.categoryIdentifier = "Medal of Freedom_DISCONNECTED"
        content.threadIdentifier = "ble-connection"

        content.userInfo = [
            "deviceName": deviceName,
            "eventType": "Medal of FreedomDisconnected",
            "timestamp": Date().timeIntervalSince1970
        ]

        let request = UNNotificationRequest(
            identifier: "Medal of Freedom-disconnection-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Clear Notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}
