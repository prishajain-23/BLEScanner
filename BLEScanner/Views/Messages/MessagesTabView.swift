//
//  MessagesTabView.swift
//  BLEScanner
//
//  Combined message history and contacts view
//

import SwiftUI

struct MessagesTabView: View {
    @State private var selectedSegment = 0
    @State private var contactService = ContactService.shared
    @State private var showHelp = false
    @State private var showMessagingSettings = false
    var bleManager: BLEManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedSegment) {
                    Text("History").tag(0)
                    Text("Contacts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selection
                if selectedSegment == 0 {
                    MessageHistoryView()
                } else {
                    ContactListView()
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMessagingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                MessagesHelpView()
            }
            .sheet(isPresented: $showMessagingSettings) {
                MessagingSettingsView(bleManager: bleManager)
            }
        }
    }
}

#Preview {
    MessagesTabView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
