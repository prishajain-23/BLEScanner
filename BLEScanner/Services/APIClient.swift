//
//  APIClient.swift
//  BLEScanner
//
//  HTTP networking layer for backend API
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received from server"
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message): return message
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .unauthorized: return "Unauthorized - please login again"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let baseURL = APIConfig.baseURL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try parsing with fractional seconds first (server format)
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601 without fractional seconds
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected date string to be ISO8601-formatted.")
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            throw APIError.invalidURL
        }

        print("🌐 API Request: \(method.rawValue) \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.timeout

        // Add authorization header if required
        if requiresAuth {
            guard let token = KeychainHelper.shared.getToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if provided
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }

            // Check for unauthorized
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            // Check for other errors
            if httpResponse.statusCode >= 400 {
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔴 Server error response: \(responseString)")
                }

                // Try to decode error message
                if let errorResponse = try? decoder.decode(GenericResponse.self, from: data),
                   let errorMessage = errorResponse.error {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            }

            // Decode response
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(endpoint: String, requiresAuth: Bool = false) async throws -> T {
        try await request(endpoint: endpoint, method: .get, requiresAuth: requiresAuth)
    }

    func post<T: Decodable>(endpoint: String, body: Encodable?, requiresAuth: Bool = false) async throws -> T {
        try await request(endpoint: endpoint, method: .post, body: body, requiresAuth: requiresAuth)
    }

    func delete<T: Decodable>(endpoint: String, requiresAuth: Bool = false) async throws -> T {
        try await request(endpoint: endpoint, method: .delete, requiresAuth: requiresAuth)
    }
}
