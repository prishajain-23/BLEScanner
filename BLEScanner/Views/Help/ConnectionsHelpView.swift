//
//  ConnectionsHelpView.swift
//  BLEScanner
//
//  Help and instructions for the Connections tab
//

import SwiftUI

struct ConnectionsHelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        Text("Device Connections")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Learn how to register and manage your Medal of Freedom")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Device Registration
                    HelpSection(
                        icon: "plus.circle.fill",
                        iconColor: .blue,
                        title: "Registering Your Device"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To register your Medal of Freedom:")
                                .fontWeight(.medium)

                            HelpStep(number: 1, text: "Tap the + button in the top right corner")
                            HelpStep(number: 2, text: "Your device should appear in the scan results")
                            HelpStep(number: 3, text: "Tap the \"Register\" button next to your device")
                            HelpStep(number: 4, text: "The sheet will close and your device will be saved")

                            Text("Once registered, the app will automatically connect to your device when it's in range.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Connection States
                    HelpSection(
                        icon: "circle.fill",
                        iconColor: .green,
                        title: "Connection States"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ConnectionStateRow(
                                color: .gray,
                                icon: "wifi.slash",
                                state: "Disconnected",
                                description: "Your device is not connected. Tap \"Reconnect\" to connect manually."
                            )

                            ConnectionStateRow(
                                color: .orange,
                                icon: "arrow.triangle.2.circlepath",
                                state: "Connecting",
                                description: "Attempting to establish connection with your device."
                            )

                            ConnectionStateRow(
                                color: .green,
                                icon: "checkmark.circle.fill",
                                state: "Connected",
                                description: "Successfully connected! Messages will be sent to contacts when this device connects."
                            )
                        }
                    }

                    // Auto-Reconnection
                    HelpSection(
                        icon: "arrow.clockwise.circle.fill",
                        iconColor: .purple,
                        title: "Auto-Reconnection"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When enabled in Settings, the app will automatically:")
                                .fontWeight(.medium)

                            BulletPoint(text: "Search for your registered device when the app opens")
                            BulletPoint(text: "Attempt to reconnect if the connection drops")
                            BulletPoint(text: "Retry up to \(BLEConfiguration.maxReconnectionAttempts) times before giving up")

                            Text("You can enable/disable auto-connect and background reconnection in Settings → BLE Connection.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Switching Devices
                    HelpSection(
                        icon: "arrow.left.arrow.right.circle.fill",
                        iconColor: .orange,
                        title: "Switching Devices"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To register a different Medal of Freedom:")
                                .fontWeight(.medium)

                            HelpStep(number: 1, text: "Go to Settings tab")
                            HelpStep(number: 2, text: "Scroll to \"BLE Connection\" section")
                            HelpStep(number: 3, text: "Tap \"Clear Auto-Connect Device\"")
                            HelpStep(number: 4, text: "Return to Connections tab")
                            HelpStep(number: 5, text: "Tap the + button to register a new device")
                        }
                    }

                    // Troubleshooting
                    HelpSection(
                        icon: "wrench.and.screwdriver.fill",
                        iconColor: .red,
                        title: "Troubleshooting"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ConnectionsTroubleshootRow(
                                problem: "Device not appearing in scan",
                                solution: "Ensure your Medal of Freedom is powered on and Bluetooth is enabled. Try tapping \"Scan for Devices\" again."
                            )

                            ConnectionsTroubleshootRow(
                                problem: "Won't connect to device",
                                solution: "Make sure your device is in range (within ~10 meters). Try restarting the Medal of Freedom and rescanning."
                            )

                            ConnectionsTroubleshootRow(
                                problem: "Keeps disconnecting",
                                solution: "Check signal strength by moving closer to the device. Enable background reconnection in Settings for better stability."
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Connections Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct HelpSection<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HelpStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.callout)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.title3)
                .foregroundStyle(.blue)
            Text(text)
                .font(.callout)
        }
    }
}

struct ConnectionStateRow: View {
    let color: Color
    let icon: String
    let state: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ConnectionsTroubleshootRow: View {
    let problem: String
    let solution: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text("Problem:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                Text(problem)
                    .font(.caption)
            }

            HStack(alignment: .top, spacing: 6) {
                Text("Solution:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                Text(solution)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConnectionsHelpView()
}
