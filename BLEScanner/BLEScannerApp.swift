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

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .onAppear {
                        // Register for push notifications after login
                        pushService.registerForRemoteNotifications()
                    }
            } else {
                AuthView()
            }
        }
    }
}
