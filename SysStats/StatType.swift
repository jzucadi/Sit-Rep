import SwiftUI

// MARK: - Stat Type Enum

enum StatType: String, CaseIterable, Identifiable {
    case cpu
    case gpu
    case ram
    case temperature

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .gpu: return "cube.transparent.fill"
        case .ram: return "memorychip"
        case .temperature: return "thermometer.medium"
        }
    }

    var label: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .ram: return "RAM"
        case .temperature: return "Temp"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .cpu: return "CPU Usage"
        case .gpu: return "GPU Usage"
        case .ram: return "Memory Usage"
        case .temperature: return "System Temperature"
        }
    }

    func accessibilityValue(from metrics: SystemMetrics, unit: TemperatureUnit = .celsius) -> String {
        switch self {
        case .cpu:
            return "\(metrics.cpuUsage) percent"
        case .gpu:
            return "\(metrics.gpuUsage) percent"
        case .ram:
            return "\(metrics.ramUsage) percent"
        case .temperature:
            if metrics.temperature > 0 {
                let temp = unit == .fahrenheit
                    ? TemperatureUtilities.celsiusToFahrenheit(metrics.temperature)
                    : metrics.temperature
                let unitName = unit == .fahrenheit ? "Fahrenheit" : "Celsius"
                return "\(Int(temp)) degrees \(unitName)"
            }
            return "Temperature unavailable"
        }
    }

    func isEnabled(in prefs: PreferencesProtocol) -> Bool {
        switch self {
        case .cpu: return prefs.showCPU
        case .gpu: return prefs.showGPU
        case .ram: return prefs.showRAM
        case .temperature: return prefs.showTemperature
        }
    }

    func value(from metrics: SystemMetrics) -> Int {
        switch self {
        case .cpu: return metrics.cpuUsage
        case .gpu: return metrics.gpuUsage
        case .ram: return metrics.ramUsage
        case .temperature: return Int(metrics.temperature)
        }
    }

    func formattedValue(from metrics: SystemMetrics, unit: TemperatureUnit = .celsius) -> String {
        switch self {
        case .cpu, .gpu, .ram:
            return "\(value(from: metrics))%"
        case .temperature:
            return metrics.temperatureString(unit: unit)
        }
    }

    func percentage(from metrics: SystemMetrics) -> Double {
        switch self {
        case .cpu, .gpu, .ram:
            return Double(value(from: metrics)) / 100.0
        case .temperature:
            // Temperature doesn't use percentage-based display
            return 0
        }
    }
}

// MARK: - Color Utilities

struct ColorUtilities {
    /// Returns color based on usage percentage (0.0 - 1.0)
    static func usageColor(for percentage: Double) -> Color {
        if percentage < UsageConstants.greenThreshold { return .green }
        if percentage < UsageConstants.orangeThreshold { return .orange }
        return .red
    }

    /// Returns color based on temperature in Celsius
    static func temperatureColor(for celsius: Double) -> Color {
        if celsius <= 0 { return .secondary }
        if celsius < TemperatureConstants.greenThreshold { return .green }
        if celsius < TemperatureConstants.orangeThreshold { return .orange }
        return .red
    }

    /// Returns the icon color for a stat type
    static func iconColor(for statType: StatType) -> Color {
        switch statType {
        case .cpu, .gpu, .ram:
            return .accentColor
        case .temperature:
            return .orange
        }
    }
}

// MARK: - Temperature Utilities

struct TemperatureUtilities {
    /// Convert Celsius to Fahrenheit
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return celsius * 9/5 + 32
    }

    /// Format temperature with unit
    static func format(_ celsius: Double, unit: TemperatureUnit) -> String {
        guard celsius > 0 else { return "—" }
        let displayTemp = unit == .fahrenheit ? celsiusToFahrenheit(celsius) : celsius
        return String(format: "%.0f%@", displayTemp, unit.label)
    }
}
