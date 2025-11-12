//
//  ContactListView.swift
//  BLEScanner
//
//  Contact management - view and manage contacts who receive auto-messages
//

import SwiftUI

struct ContactListView: View {
    @State private var contactService = ContactService.shared
    @State private var showAddContact = false
    @State private var showDeleteConfirmation = false
    @State private var contactToDelete: Contact?

    var body: some View {
        Group {
            if contactService.isLoading && contactService.contacts.isEmpty {
                ProgressView("Loading contacts...")
            } else if contactService.contacts.isEmpty {
                emptyState
            } else {
                contactList
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView()
        }
        .alert("Remove Contact", isPresented: $showDeleteConfirmation, presenting: contactToDelete) { contact in
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await contactService.removeContact(contactId: contact.id)
                }
            }
        } message: { contact in
            Text("Remove \(contact.username) from your contacts?")
        }
        .task {
            await contactService.fetchContacts()
            contactService.loadSelectedContacts()
        }
    }

    // MARK: - Contact List

    private var contactList: some View {
        List {
            Section {
                ForEach(contactService.contacts) { contact in
                    contactRow(contact)
                }
            } header: {
                Text("Your Contacts")
            } footer: {
                Text("Select contacts who will receive messages when your Medal of Freedom connects. Tap to toggle selection.")
            }
        }
        .refreshable {
            await contactService.fetchContacts()
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        HStack {
            // Checkbox
            Image(systemName: contact.isSelectedForMessaging == true ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(contact.isSelectedForMessaging == true ? .blue : .gray)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.username)
                    .font(.headline)

                if let addedAt = contact.addedAt {
                    Text("Added \(addedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Delete button
            Button(role: .destructive) {
                contactToDelete = contact
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            contactService.toggleContactSelection(contactId: contact.id)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Contacts", systemImage: "person.2.slash")
        } description: {
            Text("Add contacts to send them messages when your Medal of Freedom connects")
        } actions: {
            Button {
                showAddContact = true
            } label: {
                Text("Add Contact")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ContactListView()
}
