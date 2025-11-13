//
//  BLEScannerApp.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI

@main
struct BLEScannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authService = AuthService.shared
    @State private var pushService = PushNotificationService.shared
    @State private var locationService = LocationService.shared
    @State private var notificationManager = NotificationManager()
    @State private var shortcutManager = ShortcutManager()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView(bleManager: BLEManager(
                    notificationManager: notificationManager,
                    shortcutManager: shortcutManager
                ))
                .onAppear {
                    // Register for push notifications after login
                    pushService.registerForRemoteNotifications()

                    // Request location permissions
                    locationService.requestPermissions()
                }
            } else {
                AuthView()
            }
        }
    }
}
