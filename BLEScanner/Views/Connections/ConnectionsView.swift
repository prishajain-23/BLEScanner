//
//  ConnectionsView.swift
//  BLEScanner
//
//  Main connections view - shows medallion status and device registration
//

import SwiftUI

struct ConnectionsView: View {
    @State var bleManager: BLEManager
    @State private var showDeviceRegistration = false
    @State private var showHelp = false

    var body: some View {
        MedallionConnectionView(
            bleManager: bleManager,
            showDeviceRegistration: $showDeviceRegistration,
            showHelp: $showHelp
        )
        .sheet(isPresented: $showDeviceRegistration) {
            DeviceRegistrationView(bleManager: bleManager)
        }
        .sheet(isPresented: $showHelp) {
            ConnectionsHelpView()
        }
    }
}

#Preview {
    ConnectionsView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
