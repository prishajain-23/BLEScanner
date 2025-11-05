//
//  BLEScannerApp.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI

@main
struct BLEScannerApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}
