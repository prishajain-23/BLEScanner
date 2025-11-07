//
//  Models.swift
//  BLEScanner
//
//  Shared data models and types
//

import Foundation
import CoreBluetooth

// MARK: - Connection State
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

// MARK: - Discovered Peripheral
struct DiscoveredPeripheral: Equatable {
    var peripheral: CBPeripheral
    var advertisedData: String

    // Equatable conformance - compare by peripheral identifier
    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        lhs.peripheral.identifier == rhs.peripheral.identifier &&
        lhs.advertisedData == rhs.advertisedData
    }
}

// MARK: - BLE Configuration
struct BLEConfiguration {
    static let maxReconnectionAttempts = 5
    static let connectionTimeout: TimeInterval = 10.0
    static let initialReconnectionDelay: TimeInterval = 2.0
    static let maxReconnectionDelay: TimeInterval = 30.0
    static let scanRefreshInterval: TimeInterval = 2.0
    static let restoreIdentifierKey = "BLECentralManagerIdentifier"
}

// MARK: - User Defaults Keys
struct UserDefaultsKeys {
    static let autoConnectDeviceUUID = "AutoConnectDeviceUUID"
    static let autoConnectEnabled = "AutoConnectEnabled"
    static let shortcutName = "ShortcutToRun"
    static let allowBackgroundReconnection = "AllowBackgroundReconnection"
    static let sendNotificationOnConnect = "SendNotificationOnConnect"
}
