import Foundation
@testable import SysStats

// MARK: - Mock System Stats

class MockSystemStats: SystemStatsProtocol {
    var cpuUsage: Double = 45.0
    var ramUsage: Double = 60.0
    var gpuUsage: Double = 30.0
    var temperature: Double = 55.0

    var updateTemperatureAsyncCalled = false

    func getCPUUsage() -> Double {
        return cpuUsage
    }

    func getRAMUsage() -> Double {
        return ramUsage
    }

    func getGPUUsage() -> Double {
        return gpuUsage
    }

    func getCPUTemperature() -> Double {
        return temperature
    }

    func updateTemperatureAsync() {
        updateTemperatureAsyncCalled = true
    }
}

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
