//
//  MedallionConnectionView.swift
//  BLEScanner
//
//  Simplified medallion view showing connection status
//

import SwiftUI
import CoreBluetooth

struct MedallionConnectionView: View {
    @State var bleManager: BLEManager
    @State private var rotationAngle: Double = 0
    @State private var pulseOpacity: Double = 1.0
    @Binding var showDeviceRegistration: Bool
    @Binding var showHelp: Bool
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Medallion
                medallion

                // Status message
                Text(bleManager.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Reconnection banner
                if bleManager.isReconnecting {
                    reconnectionBanner
                }

                Spacer()

                // CTA buttons
                actionButtons

                Spacer()
            }
            .navigationTitle("Connections")
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
                        showDeviceRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    bleManager.appDidEnterForeground()
                case .background:
                    bleManager.appDidEnterBackground()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Medallion

    private var medallion: some View {
        ZStack {
            // Outer circle with state-based styling
            Circle()
                .stroke(connectionColor, lineWidth: 8)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(isConnecting ? rotationAngle : 0))
                .opacity(isConnected ? pulseOpacity : 1.0)
                .animation(isConnecting ? .linear(duration: 2).repeatForever(autoreverses: false) : nil, value: rotationAngle)
                .animation(isConnected ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : nil, value: pulseOpacity)
                .onAppear {
                    if isConnecting {
                        rotationAngle = 360
                    }
                    if isConnected {
                        pulseOpacity = 0.6
                    }
                }

            // Inner content
            VStack(spacing: 12) {
                Image(systemName: connectionIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(connectionColor)

                Text(connectionStateText)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let peripheral = bleManager.connectedPeripheral {
                    Text(peripheral.name ?? "Unknown Device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Reconnection Banner

    private var reconnectionBanner: some View {
        HStack {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reconnecting...")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("Attempt \(bleManager.reconnectionAttempt) of \(BLEConfiguration.maxReconnectionAttempts)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Stop") {
                bleManager.stopReconnecting()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            if needsRegistration {
                // No device registered - show primary registration CTA
                Button {
                    showDeviceRegistration = true
                } label: {
                    Label("Register Device", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Text("Tap the + button or this button to register your Medal of Freedom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else if canReconnect {
                // Device registered but disconnected - show reconnect option
                Button {
                    reconnectToDevice()
                } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Text("Manually reconnect to your registered device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Computed Properties

    private var connectionColor: Color {
        switch bleManager.connectionState {
        case .disconnected:
            return .gray
        case .connecting, .disconnecting:
            return .orange
        case .connected:
            return .green
        }
    }

    private var connectionIcon: String {
        switch bleManager.connectionState {
        case .disconnected:
            return "wifi.slash"
        case .connecting, .disconnecting:
            return "arrow.triangle.2.circlepath"
        case .connected:
            return "checkmark.circle.fill"
        }
    }

    private var connectionStateText: String {
        switch bleManager.connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        }
    }

    private var isConnecting: Bool {
        bleManager.connectionState == .connecting
    }

    private var isConnected: Bool {
        bleManager.connectionState == .connected
    }

    private var needsRegistration: Bool {
        UserDefaults.standard.string(forKey: UserDefaultsKeys.autoConnectDeviceUUID) == nil
    }

    private var canReconnect: Bool {
        !needsRegistration && bleManager.connectionState == .disconnected && !bleManager.isReconnecting
    }

    // MARK: - Actions

    private func reconnectToDevice() {
        // Enable auto-connect if not already enabled
        if !bleManager.autoConnectEnabled {
            bleManager.autoConnectEnabled = true
        }

        // Start scanning to find the device
        if !bleManager.isScanning {
            bleManager.startScan()
        }
    }
}

#Preview {
    @Previewable @State var showRegistration = false
    @Previewable @State var showHelp = false

    MedallionConnectionView(
        bleManager: BLEManager(
            notificationManager: NotificationManager(),
            shortcutManager: ShortcutManager()
        ),
        showDeviceRegistration: $showRegistration,
        showHelp: $showHelp
    )
}
