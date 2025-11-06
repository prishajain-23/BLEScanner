//
//  ContactService.swift
//  BLEScanner
//
//  Manages contacts and user search
//

import Foundation
import Observation

@Observable
class ContactService {
    static let shared = ContactService()

    @MainActor var contacts: [Contact] = []
    @MainActor var isLoading = false
    @MainActor var errorMessage: String?

    private let apiClient = APIClient.shared
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 60 // Cache for 60 seconds

    private init() {}

    // MARK: - Fetch Contacts

    /// Fetch the user's contact list (with caching)
    func fetchContacts(forceRefresh: Bool = false) async {
        // Check cache first
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            print("📦 Using cached contacts (\(await contacts.count) contacts)")
            return
        }

        await MainActor.run { isLoading = true }
        await MainActor.run { errorMessage = nil }

        do {
            let response: ContactsResponse = try await apiClient.get(
                endpoint: APIEndpoints.contacts,
                requiresAuth: true
            )

            if response.success, let fetchedContacts = response.contacts {
                await MainActor.run {
                    contacts = fetchedContacts
                }
                lastFetchTime = Date()
                print("✅ Fetched \(fetchedContacts.count) contacts")
            } else {
                await MainActor.run {
                    errorMessage = response.error ?? "Failed to fetch contacts"
                }
                print("❌ Error: \(errorMessage ?? "Unknown")")
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            print("❌ Error fetching contacts: \(error.localizedDescription)")
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Search Users

    /// Search for users by username
    /// - Parameter query: Search query (username)
    /// - Returns: Array of matching users
    func searchUsers(query: String) async -> [User] {
        guard !query.isEmpty else { return [] }

        do {
            let endpoint = APIEndpoints.userSearch + "?q=\(query)"
            let response: UserSearchResponse = try await apiClient.get(
                endpoint: endpoint,
                requiresAuth: true
            )

            if response.success, let users = response.users {
                print("✅ Found \(users.count) users matching '\(query)'")
                return users
            } else {
                print("❌ Search failed: \(response.error ?? "Unknown")")
                return []
            }
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Add Contact

    /// Add a user as a contact
    /// - Parameter username: Username to add
    func addContact(username: String) async -> Bool {
        await MainActor.run { isLoading = true }
        await MainActor.run { errorMessage = nil }

        do {
            struct AddContactRequest: Encodable {
                let contact_username: String
            }

            let request = AddContactRequest(contact_username: username)
            let response: ContactsResponse = try await apiClient.post(
                endpoint: APIEndpoints.addContact,
                body: request,
                requiresAuth: true
            )

            if response.success {
                print("✅ Added contact: \(username)")
                // Refresh contacts list (force refresh to get new contact)
                await fetchContacts(forceRefresh: true)
                await MainActor.run { isLoading = false }
                return true
            } else {
                await MainActor.run {
                    errorMessage = response.error ?? "Failed to add contact"
                    isLoading = false
                }
                print("❌ Error: \(errorMessage ?? "Unknown")")
                return false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            print("❌ Error adding contact: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Remove Contact

    /// Remove a contact
    /// - Parameter contactId: ID of the contact to remove
    func removeContact(contactId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let endpoint = APIEndpoints.removeContact(contactId)
            let response: GenericResponse = try await apiClient.delete(
                endpoint: endpoint,
                requiresAuth: true
            )

            if response.success {
                print("✅ Removed contact ID: \(contactId)")
                // Remove from local array
                contacts.removeAll { $0.id == contactId }
                isLoading = false
                return true
            } else {
                errorMessage = response.error ?? "Failed to remove contact"
                print("❌ Error: \(errorMessage ?? "Unknown")")
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error removing contact: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    // MARK: - Contact Selection for Messaging

    /// Get selected contact IDs for messaging
    var selectedContactIds: [Int] {
        contacts.filter { $0.isSelectedForMessaging ?? false }.map { $0.id }
    }

    /// Toggle contact selection for messaging
    func toggleContactSelection(contactId: Int) {
        if let index = contacts.firstIndex(where: { $0.id == contactId }) {
            contacts[index].isSelectedForMessaging?.toggle()
            saveSelectedContacts()
        }
    }

    /// Save selected contacts to UserDefaults
    private func saveSelectedContacts() {
        let selectedIds = selectedContactIds
        UserDefaults.standard.set(selectedIds, forKey: "selectedContactIds")
        print("💾 Saved selected contacts: \(selectedIds)")
    }

    /// Load selected contacts from UserDefaults
    func loadSelectedContacts() {
        guard let savedIds = UserDefaults.standard.array(forKey: "selectedContactIds") as? [Int] else {
            return
        }

        for id in savedIds {
            if let index = contacts.firstIndex(where: { $0.id == id }) {
                contacts[index].isSelectedForMessaging = true
            }
        }
        print("📂 Loaded selected contacts: \(savedIds)")
    }
}
