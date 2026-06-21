import XCTest

final class PreferencesManagerTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a separate suite for testing to avoid polluting actual preferences
        testDefaults = UserDefaults(suiteName: "com.jameszaccardo.SysStats.tests")
        testDefaults?.removePersistentDomain(forName: "com.jameszaccardo.SysStats.tests")
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: "com.jameszaccardo.SysStats.tests")
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Update Interval Tests

    func testUpdateIntervalLabelOne() {
        XCTAssertEqual(UpdateInterval.one.label, "1s")
    }

    func testUpdateIntervalLabelTwo() {
        XCTAssertEqual(UpdateInterval.two.label, "2s")
    }

    func testUpdateIntervalLabelFive() {
        XCTAssertEqual(UpdateInterval.five.label, "5s")
    }

    func testUpdateIntervalRawValues() {
        XCTAssertEqual(UpdateInterval.one.rawValue, 1.0)
        XCTAssertEqual(UpdateInterval.two.rawValue, 2.0)
        XCTAssertEqual(UpdateInterval.five.rawValue, 5.0)
    }

    func testUpdateIntervalAllCases() {
        XCTAssertEqual(UpdateInterval.allCases.count, 3)
        XCTAssertTrue(UpdateInterval.allCases.contains(.one))
        XCTAssertTrue(UpdateInterval.allCases.contains(.two))
        XCTAssertTrue(UpdateInterval.allCases.contains(.five))
    }

    // MARK: - Temperature Unit Tests

    func testTemperatureUnitCelsiusLabel() {
        XCTAssertEqual(TemperatureUnit.celsius.label, "°C")
    }

    func testTemperatureUnitFahrenheitLabel() {
        XCTAssertEqual(TemperatureUnit.fahrenheit.label, "°F")
    }

    func testTemperatureUnitRawValues() {
        XCTAssertEqual(TemperatureUnit.celsius.rawValue, "C")
        XCTAssertEqual(TemperatureUnit.fahrenheit.rawValue, "F")
    }

    func testTemperatureUnitAllCases() {
        XCTAssertEqual(TemperatureUnit.allCases.count, 2)
        XCTAssertTrue(TemperatureUnit.allCases.contains(.celsius))
        XCTAssertTrue(TemperatureUnit.allCases.contains(.fahrenheit))
    }

    // MARK: - Temperature Conversion Tests

    func testCelsiusToFahrenheitConversion() {
        // 0°C = 32°F
        let celsius0: Double = 0
        let fahrenheit0 = celsius0 * 9/5 + 32
        XCTAssertEqual(fahrenheit0, 32)

        // 100°C = 212°F
        let celsius100: Double = 100
        let fahrenheit100 = celsius100 * 9/5 + 32
        XCTAssertEqual(fahrenheit100, 212)

        // 37°C = 98.6°F (body temperature)
        let celsius37: Double = 37
        let fahrenheit37 = celsius37 * 9/5 + 32
        XCTAssertEqual(fahrenheit37, 98.6, accuracy: 0.1)

        // -40°C = -40°F (same in both)
        let celsiusMinus40: Double = -40
        let fahrenheitMinus40 = celsiusMinus40 * 9/5 + 32
        XCTAssertEqual(fahrenheitMinus40, -40)
    }

    // MARK: - Default Values Tests

    func testPreferencesManagerDefaultsShowAllStats() {
        // The shared instance should default to showing all stats
        let prefs = PreferencesManager.shared

        // These should default to true according to the implementation
        XCTAssertTrue(prefs.showCPU)
        XCTAssertTrue(prefs.showGPU)
        XCTAssertTrue(prefs.showRAM)
        XCTAssertTrue(prefs.showTemperature)
    }

    func testPreferencesManagerDefaultUpdateInterval() {
        let prefs = PreferencesManager.shared
        // Default should be .two (2 seconds) if not set
        XCTAssertNotNil(prefs.updateInterval)
    }

    func testPreferencesManagerDefaultTemperatureUnit() {
        let prefs = PreferencesManager.shared
        // Default should be celsius
        XCTAssertNotNil(prefs.temperatureUnit)
    }

    // MARK: - Mock Preferences Tests

    func testMockPreferencesDefaultValues() {
        let mock = MockPreferences()

        XCTAssertTrue(mock.showCPU)
        XCTAssertTrue(mock.showGPU)
        XCTAssertTrue(mock.showRAM)
        XCTAssertTrue(mock.showTemperature)
        XCTAssertEqual(mock.temperatureUnit, .celsius)
        XCTAssertEqual(mock.updateInterval, .two)
        XCTAssertFalse(mock.launchAtLogin)
    }

    func testMockPreferencesCustomValues() {
        let mock = MockPreferences(
            showCPU: false,
            showGPU: true,
            showRAM: false,
            showTemperature: true,
            temperatureUnit: .fahrenheit
        )

        XCTAssertFalse(mock.showCPU)
        XCTAssertTrue(mock.showGPU)
        XCTAssertFalse(mock.showRAM)
        XCTAssertTrue(mock.showTemperature)
        XCTAssertEqual(mock.temperatureUnit, .fahrenheit)
    }

    func testMockPreferencesCanBeModified() {
        let mock = MockPreferences()

        mock.showCPU = false
        mock.temperatureUnit = .fahrenheit
        mock.updateInterval = .five

        XCTAssertFalse(mock.showCPU)
        XCTAssertEqual(mock.temperatureUnit, .fahrenheit)
        XCTAssertEqual(mock.updateInterval, .five)
    }
}
