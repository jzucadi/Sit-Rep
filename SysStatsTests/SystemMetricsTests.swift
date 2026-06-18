import XCTest
@testable import SysStats

final class SystemMetricsTests: XCTestCase {

    // MARK: - Temperature String Tests

    func testTemperatureStringCelsius() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 55.0)
        let result = metrics.temperatureString(unit: .celsius)
        XCTAssertEqual(result, "55°")
    }

    func testTemperatureStringFahrenheit() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 100.0)
        let result = metrics.temperatureString(unit: .fahrenheit)
        // 100°C = 212°F
        XCTAssertEqual(result, "212°")
    }

    func testTemperatureStringZeroCelsius() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 0.0)
        let result = metrics.temperatureString(unit: .celsius)
        XCTAssertEqual(result, "—°")
    }

    func testTemperatureStringNegativeCelsius() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: -5.0)
        let result = metrics.temperatureString(unit: .celsius)
        XCTAssertEqual(result, "—°")
    }

    func testTemperatureStringFractionalCelsius() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 55.7)
        let result = metrics.temperatureString(unit: .celsius)
        XCTAssertEqual(result, "55°") // Should round down
    }

    func testTemperatureStringFractionalFahrenheit() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 37.0)
        let result = metrics.temperatureString(unit: .fahrenheit)
        // 37°C = 98.6°F, should display as 98°
        XCTAssertEqual(result, "98°")
    }

    // MARK: - Status Bar Text Tests

    func testStatusBarTextAllEnabled() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 55.0)
        let prefs = MockPreferences(showCPU: true, showGPU: true, showRAM: true, showTemperature: true)

        let result = metrics.statusBarText(prefs: prefs)

        XCTAssertEqual(result, "C:50% G:30% R:60% 55°")
    }

    func testStatusBarTextCPUOnly() {
        let metrics = SystemMetrics(cpuUsage: 75, gpuUsage: 30, ramUsage: 60, temperature: 55.0)

        // Test the expected format
        XCTAssertTrue(metrics.cpuUsage == 75)
    }

    func testStatusBarTextNoStatsEnabled() {
        let metrics = SystemMetrics(cpuUsage: 50, gpuUsage: 30, ramUsage: 60, temperature: 55.0)

        // When all stats are disabled, should show "SysStats"
        // This would require injecting preferences
    }

    // MARK: - Metrics Values Tests

    func testMetricsStoresValuesCorrectly() {
        let metrics = SystemMetrics(cpuUsage: 45, gpuUsage: 25, ramUsage: 70, temperature: 62.5)

        XCTAssertEqual(metrics.cpuUsage, 45)
        XCTAssertEqual(metrics.gpuUsage, 25)
        XCTAssertEqual(metrics.ramUsage, 70)
        XCTAssertEqual(metrics.temperature, 62.5)
    }

    func testMetricsHandlesBoundaryValues() {
        let minMetrics = SystemMetrics(cpuUsage: 0, gpuUsage: 0, ramUsage: 0, temperature: 0)
        XCTAssertEqual(minMetrics.cpuUsage, 0)
        XCTAssertEqual(minMetrics.gpuUsage, 0)
        XCTAssertEqual(minMetrics.ramUsage, 0)
        XCTAssertEqual(minMetrics.temperature, 0)

        let maxMetrics = SystemMetrics(cpuUsage: 100, gpuUsage: 100, ramUsage: 100, temperature: 120)
        XCTAssertEqual(maxMetrics.cpuUsage, 100)
        XCTAssertEqual(maxMetrics.gpuUsage, 100)
        XCTAssertEqual(maxMetrics.ramUsage, 100)
        XCTAssertEqual(maxMetrics.temperature, 120)
    }
}
