import AppKit
import os.log

// MARK: - App Constants

enum AppConstants {
    static let appName = "SysStats"
    static let bundleIdentifier = "com.jameszaccardo.SysStats"
}

// MARK: - UI Constants

enum UIConstants {
    enum StatusBar {
        static let fontSize: CGFloat = 11
        static let fontWeight: NSFont.Weight = .regular
        static let iconPointSize: CGFloat = 11
        static let iconWeight: NSFont.Weight = .medium
        static let statSeparator = "  "  // Double space between stats for readability
    }

    enum Popover {
        static let width: CGFloat = 300
        static let height: CGFloat = 320
        static let contentWidth: CGFloat = 280
    }

    enum StatRow {
        static let iconWidth: CGFloat = 20
        static let labelWidth: CGFloat = 40
        static let valueWidth: CGFloat = 40
        static let barHeight: CGFloat = 8
        static let barCornerRadius: CGFloat = 3
        static let spacing: CGFloat = 8
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 12
        static let itemSpacing: CGFloat = 10
        static let preferenceItemSpacing: CGFloat = 6
    }
}

// MARK: - Temperature Constants

enum TemperatureConstants {
    /// Minimum valid temperature reading in Celsius
    static let minimumValid: Double = 10

    /// Maximum valid temperature reading in Celsius
    static let maximumValid: Double = 120

    /// Temperature threshold for green color (below this = green)
    static let greenThreshold: Double = 50

    /// Temperature threshold for orange color (below this = orange, above = red)
    static let orangeThreshold: Double = 70
}

// MARK: - Usage Constants

enum UsageConstants {
    /// Percentage threshold for green color (below this = green)
    static let greenThreshold: Double = 0.5

    /// Percentage threshold for orange color (below this = orange, above = red)
    static let orangeThreshold: Double = 0.8
}

// MARK: - Logging

enum Log {
    private static let subsystem = AppConstants.bundleIdentifier

    static let general = Logger(subsystem: subsystem, category: "general")
    static let stats = Logger(subsystem: subsystem, category: "stats")
    static let temperature = Logger(subsystem: subsystem, category: "temperature")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}

// MARK: - Validation Helpers

extension TemperatureConstants {
    /// Check if a temperature reading is within valid bounds
    static func isValid(_ temperature: Double) -> Bool {
        temperature > minimumValid && temperature < maximumValid
    }
}

extension UsageConstants {
    /// Clamp a percentage value to valid range (0.0 - 1.0)
    static func clampPercentage(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
