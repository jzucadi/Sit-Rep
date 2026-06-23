import Foundation

// MARK: - Preferences Protocol

protocol PreferencesProtocol: AnyObject {
    var updateInterval: UpdateInterval { get set }
    var showCPU: Bool { get set }
    var showGPU: Bool { get set }
    var showRAM: Bool { get set }
    var showTemperature: Bool { get set }
    var temperatureUnit: TemperatureUnit { get set }
    var launchAtLogin: Bool { get set }
}

// MARK: - Protocol Conformance Extensions

extension PreferencesManager: PreferencesProtocol {}
