import Foundation

// MARK: - Mock Preferences

class MockPreferences: PreferencesProtocol {
    var updateInterval: UpdateInterval = .two
    var showCPU: Bool = true
    var showGPU: Bool = true
    var showRAM: Bool = true
    var showTemperature: Bool = true
    var temperatureUnit: TemperatureUnit = .celsius
    var launchAtLogin: Bool = false

    init(
        showCPU: Bool = true,
        showGPU: Bool = true,
        showRAM: Bool = true,
        showTemperature: Bool = true,
        temperatureUnit: TemperatureUnit = .celsius
    ) {
        self.showCPU = showCPU
        self.showGPU = showGPU
        self.showRAM = showRAM
        self.showTemperature = showTemperature
        self.temperatureUnit = temperatureUnit
    }
}
