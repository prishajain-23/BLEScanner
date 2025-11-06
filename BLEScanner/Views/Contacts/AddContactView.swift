//
//  AddContactView.swift
//  BLEScanner
//
//  Search for users and add them as contacts
//

import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var contactService = ContactService.shared
    @State private var searchQuery = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var showSuccess = false
    @State private var successMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Results or empty state
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchQuery.isEmpty {
                    emptyState
                } else if searchResults.isEmpty {
                    noResultsState
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Username", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))

            Divider()
        }
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        List {
            Section {
                ForEach(searchResults) { user in
                    userRow(user)
                }
            } header: {
                Text("Search Results")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func userRow(_ user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)

                if let createdAt = user.createdAt {
                    Text("Joined \(createdAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Check if already a contact
            if contactService.contacts.contains(where: { $0.username == user.username }) {
                Text("Already added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    addContact(user)
                } label: {
                    Text("Add")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Search for Users", systemImage: "magnifyingglass")
        } description: {
            Text("Enter a username to find users and add them as contacts")
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "person.slash")
        } description: {
            Text("No users found matching '\(searchQuery)'")
        }
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        Task {
            searchResults = await contactService.searchUsers(query: searchQuery)
            isSearching = false
        }
    }

    private func addContact(_ user: User) {
        Task {
            let success = await contactService.addContact(username: user.username)
            if success {
                successMessage = "Added \(user.username) to your contacts"
                showSuccess = true
            }
        }
    }
}

#Preview {
    AddContactView()
}
