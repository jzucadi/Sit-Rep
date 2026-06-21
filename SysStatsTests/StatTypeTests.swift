import XCTest

final class StatTypeTests: XCTestCase {

    // MARK: - StatType Icon Tests

    func testStatTypeIcons() {
        XCTAssertEqual(StatType.cpu.icon, "cpu")
        XCTAssertEqual(StatType.gpu.icon, "cube.transparent.fill")
        XCTAssertEqual(StatType.ram.icon, "memorychip")
        XCTAssertEqual(StatType.temperature.icon, "thermometer.medium")
    }

    // MARK: - StatType Label Tests

    func testStatTypeLabels() {
        XCTAssertEqual(StatType.cpu.label, "CPU")
        XCTAssertEqual(StatType.gpu.label, "GPU")
        XCTAssertEqual(StatType.ram.label, "RAM")
        XCTAssertEqual(StatType.temperature.label, "Temp")
    }

    func testStatTypePreferencesLabels() {
        XCTAssertEqual(StatType.cpu.preferencesLabel, "CPU Usage")
        XCTAssertEqual(StatType.gpu.preferencesLabel, "GPU Usage")
        XCTAssertEqual(StatType.ram.preferencesLabel, "RAM Usage")
        XCTAssertEqual(StatType.temperature.preferencesLabel, "Temperature")
    }

    // MARK: - StatType All Cases

    func testStatTypeAllCases() {
        XCTAssertEqual(StatType.allCases.count, 4)
        XCTAssertTrue(StatType.allCases.contains(.cpu))
        XCTAssertTrue(StatType.allCases.contains(.gpu))
        XCTAssertTrue(StatType.allCases.contains(.ram))
        XCTAssertTrue(StatType.allCases.contains(.temperature))
    }

    // MARK: - StatType Value Extraction

    func testStatTypeValueFromMetrics() {
        let metrics = SystemMetrics(cpuUsage: 45, gpuUsage: 30, ramUsage: 65, temperature: 55.0)

        XCTAssertEqual(StatType.cpu.value(from: metrics), 45)
        XCTAssertEqual(StatType.gpu.value(from: metrics), 30)
        XCTAssertEqual(StatType.ram.value(from: metrics), 65)
        XCTAssertEqual(StatType.temperature.value(from: metrics), 55)
    }

    func testStatTypeFormattedValue() {
        let metrics = SystemMetrics(cpuUsage: 45, gpuUsage: 30, ramUsage: 65, temperature: 55.0)

        XCTAssertEqual(StatType.cpu.formattedValue(from: metrics), "45%")
        XCTAssertEqual(StatType.gpu.formattedValue(from: metrics), "30%")
        XCTAssertEqual(StatType.ram.formattedValue(from: metrics), "65%")
        XCTAssertEqual(StatType.temperature.formattedValue(from: metrics, unit: .celsius), "55°")
    }

    func testStatTypePercentage() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 80, ramUsage: 25, temperature: 55.0)

        XCTAssertEqual(StatType.cpu.percentage(from: metrics), 0.5, accuracy: 0.01)
        XCTAssertEqual(StatType.gpu.percentage(from: metrics), 0.8, accuracy: 0.01)
        XCTAssertEqual(StatType.ram.percentage(from: metrics), 0.25, accuracy: 0.01)
        XCTAssertEqual(StatType.temperature.percentage(from: metrics), 0) // Temperature doesn't use percentage
    }

    // MARK: - StatType IsEnabled Tests

    func testStatTypeIsEnabled() {
        let allEnabled = MockPreferences(showCPU: true, showGPU: true, showRAM: true, showTemperature: true)
        XCTAssertTrue(StatType.cpu.isEnabled(in: allEnabled))
        XCTAssertTrue(StatType.gpu.isEnabled(in: allEnabled))
        XCTAssertTrue(StatType.ram.isEnabled(in: allEnabled))
        XCTAssertTrue(StatType.temperature.isEnabled(in: allEnabled))

        let noneEnabled = MockPreferences(showCPU: false, showGPU: false, showRAM: false, showTemperature: false)
        XCTAssertFalse(StatType.cpu.isEnabled(in: noneEnabled))
        XCTAssertFalse(StatType.gpu.isEnabled(in: noneEnabled))
        XCTAssertFalse(StatType.ram.isEnabled(in: noneEnabled))
        XCTAssertFalse(StatType.temperature.isEnabled(in: noneEnabled))
    }
}

// MARK: - Color Utilities Tests

final class ColorUtilitiesTests: XCTestCase {

    func testUsageColorGreen() {
        // Below green threshold should be green
        XCTAssertEqual(ColorUtilities.usageColor(for: 0.0), .green)
        XCTAssertEqual(ColorUtilities.usageColor(for: 0.25), .green)
        XCTAssertEqual(ColorUtilities.usageColor(for: UsageConstants.greenThreshold - 0.01), .green)
    }

    func testUsageColorOrange() {
        // Between green and orange threshold should be orange
        XCTAssertEqual(ColorUtilities.usageColor(for: UsageConstants.greenThreshold), .orange)
        XCTAssertEqual(ColorUtilities.usageColor(for: 0.65), .orange)
        XCTAssertEqual(ColorUtilities.usageColor(for: UsageConstants.orangeThreshold - 0.01), .orange)
    }

    func testUsageColorRed() {
        // At or above orange threshold should be red
        XCTAssertEqual(ColorUtilities.usageColor(for: UsageConstants.orangeThreshold), .red)
        XCTAssertEqual(ColorUtilities.usageColor(for: 0.9), .red)
        XCTAssertEqual(ColorUtilities.usageColor(for: 1.0), .red)
    }

    func testTemperatureColorSecondary() {
        // 0 or below should be secondary
        XCTAssertEqual(ColorUtilities.temperatureColor(for: 0), .secondary)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: -10), .secondary)
    }

    func testTemperatureColorGreen() {
        // Below green threshold should be green
        XCTAssertEqual(ColorUtilities.temperatureColor(for: 30), .green)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: TemperatureConstants.greenThreshold - 1), .green)
    }

    func testTemperatureColorOrange() {
        // Between green and orange threshold should be orange
        XCTAssertEqual(ColorUtilities.temperatureColor(for: TemperatureConstants.greenThreshold), .orange)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: 60), .orange)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: TemperatureConstants.orangeThreshold - 1), .orange)
    }

    func testTemperatureColorRed() {
        // At or above orange threshold should be red
        XCTAssertEqual(ColorUtilities.temperatureColor(for: TemperatureConstants.orangeThreshold), .red)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: 85), .red)
        XCTAssertEqual(ColorUtilities.temperatureColor(for: 100), .red)
    }

    func testTemperatureIsValid() {
        XCTAssertFalse(TemperatureConstants.isValid(0))
        XCTAssertFalse(TemperatureConstants.isValid(10))
        XCTAssertTrue(TemperatureConstants.isValid(50))
        XCTAssertTrue(TemperatureConstants.isValid(100))
        XCTAssertFalse(TemperatureConstants.isValid(120))
        XCTAssertFalse(TemperatureConstants.isValid(150))
    }

    func testClampPercentage() {
        XCTAssertEqual(UsageConstants.clampPercentage(-0.5), 0)
        XCTAssertEqual(UsageConstants.clampPercentage(0.0), 0)
        XCTAssertEqual(UsageConstants.clampPercentage(0.5), 0.5)
        XCTAssertEqual(UsageConstants.clampPercentage(1.0), 1)
        XCTAssertEqual(UsageConstants.clampPercentage(1.5), 1)
    }
}

// MARK: - Temperature Utilities Tests

final class TemperatureUtilitiesTests: XCTestCase {

    func testCelsiusToFahrenheitConversion() {
        XCTAssertEqual(TemperatureUtilities.celsiusToFahrenheit(0), 32)
        XCTAssertEqual(TemperatureUtilities.celsiusToFahrenheit(100), 212)
        XCTAssertEqual(TemperatureUtilities.celsiusToFahrenheit(37), 98.6, accuracy: 0.1)
        XCTAssertEqual(TemperatureUtilities.celsiusToFahrenheit(-40), -40)
    }

    func testFormatCelsius() {
        XCTAssertEqual(TemperatureUtilities.format(55.0, unit: .celsius), "55°C")
        XCTAssertEqual(TemperatureUtilities.format(37.5, unit: .celsius), "38°C") // Rounds
    }

    func testFormatFahrenheit() {
        XCTAssertEqual(TemperatureUtilities.format(100.0, unit: .fahrenheit), "212°F")
        XCTAssertEqual(TemperatureUtilities.format(0.0, unit: .fahrenheit), "—") // Zero returns dash
    }

    func testFormatZeroTemperature() {
        XCTAssertEqual(TemperatureUtilities.format(0.0, unit: .celsius), "—")
        XCTAssertEqual(TemperatureUtilities.format(-5.0, unit: .celsius), "—")
    }

    func testFormatShortCelsius() {
        XCTAssertEqual(TemperatureUtilities.formatShort(55.0, unit: .celsius), "55°")
        XCTAssertEqual(TemperatureUtilities.formatShort(0.0, unit: .celsius), "—°")
    }

    func testFormatShortFahrenheit() {
        XCTAssertEqual(TemperatureUtilities.formatShort(100.0, unit: .fahrenheit), "212°")
    }
}
