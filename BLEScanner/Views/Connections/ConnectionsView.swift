//
//  ConnectionsView.swift
//  BLEScanner
//
//  BLE device scanning and connection management
//

import SwiftUI
import CoreBluetooth

struct ConnectionsView: View {
    @State var bleManager: BLEManager
    @State private var searchText = ""
    @State private var filteredResults: [DiscoveredPeripheral] = []
    @State private var showAutomationGuide = false
    @Environment(\.scenePhase) var scenePhase

    private let searchDebouncer = Debouncer(delay: .milliseconds(150))

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                statusBar

                // Reconnection warning banner
                if bleManager.isReconnecting {
                    reconnectionBanner
                }

                // Search bar
                searchBar

                // Device list
                deviceList

                // Bottom controls
                bottomControls
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAutomationGuide = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showAutomationGuide) {
                AutomationGuideView()
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
    }

    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 10, height: 10)

            Text(bleManager.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if bleManager.connectionState == .connected,
               let peripheral = bleManager.connectedPeripheral {
                Text(peripheral.name ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var connectionStatusColor: Color {
        switch bleManager.connectionState {
        case .disconnected:
            return .gray
        case .connecting, .disconnecting:
            return .orange
        case .connected:
            return .green
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            TextField("Search devices", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        await searchDebouncer.submit {
                            await filterPeripherals(query: newValue)
                        }
                    }
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Device List
    private var deviceList: some View {
        List(searchText.isEmpty ? bleManager.discoveredPeripherals : filteredResults,
             id: \.peripheral.identifier) { discoveredPeripheral in
            DeviceRow(
                peripheral: discoveredPeripheral.peripheral,
                advertisedData: discoveredPeripheral.advertisedData,
                isConnected: bleManager.connectedPeripheral?.identifier == discoveredPeripheral.peripheral.identifier,
                connectionState: bleManager.connectionState,
                onConnect: {
                    bleManager.connect(to: discoveredPeripheral.peripheral)
                },
                onDisconnect: {
                    bleManager.disconnect()
                },
                onSetAutoConnect: {
                    bleManager.setAutoConnectDevice(discoveredPeripheral.peripheral)
                    bleManager.autoConnectEnabled = true
                }
            )
        }
        .listStyle(.plain)
    }

    // MARK: - Helper Functions

    /// Filter peripherals in background thread to avoid blocking UI
    @Sendable
    private func filterPeripherals(query: String) async {
        let peripherals = bleManager.discoveredPeripherals

        // Perform filtering off main thread
        let filtered = await Task.detached {
            if query.isEmpty {
                return peripherals
            }
            let lowercasedQuery = query.lowercased()
            return peripherals.filter {
                $0.peripheral.name?.lowercased().contains(lowercasedQuery) == true
            }
        }.value

        // Update UI on main thread
        await MainActor.run {
            filteredResults = filtered
        }
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if bleManager.connectionState == .connected {
                Button(action: {
                    bleManager.disconnect()
                }) {
                    Text("Disconnect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
            }

            Button(action: {
                if bleManager.isScanning {
                    bleManager.stopScan()
                } else {
                    bleManager.startScan()
                }
            }) {
                Text(bleManager.isScanning ? "Stop Scanning" : "Scan for Devices")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(bleManager.isScanning ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Device Row
struct DeviceRow: View {
    let peripheral: CBPeripheral
    let advertisedData: String
    let isConnected: Bool
    let connectionState: ConnectionState
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onSetAutoConnect: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(peripheral.name ?? "Unknown Device")
                        .font(.headline)

                    Text(peripheral.identifier.uuidString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if showDetails {
                Text(advertisedData)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 4)
            }

            HStack(spacing: 8) {
                Button(action: {
                    showDetails.toggle()
                }) {
                    Label(showDetails ? "Hide Details" : "Show Details", systemImage: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if !isConnected && connectionState == .disconnected {
                    Button(action: onConnect) {
                        Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(action: onSetAutoConnect) {
                        Label("Auto", systemImage: "bolt.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if isConnected {
                    Button(action: onDisconnect) {
                        Label("Disconnect", systemImage: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConnectionsView(bleManager: BLEManager(
        notificationManager: NotificationManager(),
        shortcutManager: ShortcutManager()
    ))
}
