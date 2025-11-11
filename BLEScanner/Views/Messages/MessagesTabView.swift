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
    @State private var showAddContact = false

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
                if selectedSegment == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddContact = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView()
            }
        }
    }
}

#Preview {
    MessagesTabView()
}
