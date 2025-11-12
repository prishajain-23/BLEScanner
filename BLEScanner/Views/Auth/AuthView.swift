//
//  AuthView.swift
//  BLEScanner
//
//  Combined Login and Register view
//

import SwiftUI

struct AuthView: View {
    @State private var authService = AuthService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isRegistering = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("MOF")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(isRegistering ? "Create Account" : "Welcome Back")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // Form
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: handleAuth) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isRegistering ? "Register" : "Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(authService.isLoading || username.isEmpty || password.isEmpty)

                    Button(action: { isRegistering.toggle() }) {
                        Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                Text("Messages will be sent when your Medal of Freedom connects")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }

    private func handleAuth() {
        Task {
            if isRegistering {
                await authService.register(username: username, password: password)
            } else {
                await authService.login(username: username, password: password)
            }
        }
    }
}

#Preview {
    AuthView()
}
