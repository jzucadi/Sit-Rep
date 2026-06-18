import Foundation
import Combine

struct SystemMetrics {
    let cpuUsage: Int
    let gpuUsage: Int
    let ramUsage: Int
    let temperature: Double

    func temperatureString(unit: TemperatureUnit) -> String {
        if temperature > 0 {
            let displayTemp = unit == .fahrenheit ? temperature * 9/5 + 32 : temperature
            return String(format: "%d°", Int(displayTemp))
        } else {
            return "—°"
        }
    }

    func statusBarText(prefs: PreferencesProtocol) -> String {
        var components: [String] = []

        if prefs.showCPU {
            components.append(String(format: "C:%d%%", cpuUsage))
        }
        if prefs.showGPU {
            components.append(String(format: "G:%d%%", gpuUsage))
        }
        if prefs.showRAM {
            components.append(String(format: "R:%d%%", ramUsage))
        }
        if prefs.showTemperature {
            components.append(temperatureString(unit: prefs.temperatureUnit))
        }

        return components.isEmpty ? "SysStats" : components.joined(separator: " ")
    }
}

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published private(set) var currentMetrics: SystemMetrics = SystemMetrics(
        cpuUsage: 0,
        gpuUsage: 0,
        ramUsage: 0,
        temperature: 0
    )

    private var updateTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observePreferences()
    }

    private func observePreferences() {
        PreferencesManager.shared.$updateInterval
            .sink { [weak self] _ in
                self?.restartMonitoring()
            }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        stopMonitoring()

        let interval = PreferencesManager.shared.updateInterval.rawValue

        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchAllMetrics()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    private func restartMonitoring() {
        if updateTask != nil {
            startMonitoring()
        }
    }

    func stopMonitoring() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func fetchAllMetrics() async {
        async let cpuTask = fetchCPUUsage()
        async let gpuTask = fetchGPUUsage()
        async let ramTask = fetchRAMUsage()
        async let tempTask = fetchTemperature()

        let (cpu, gpu, ram, temp) = await (cpuTask, gpuTask, ramTask, tempTask)

        currentMetrics = SystemMetrics(
            cpuUsage: cpu,
            gpuUsage: gpu,
            ramUsage: ram,
            temperature: temp
        )
    }

    // MARK: - Metric Fetching

    private func fetchMetric<T>(_ fetch: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: fetch())
            }
        }
    }

    private func fetchCPUUsage() async -> Int {
        await fetchMetric { Int(SystemStats.shared.getCPUUsage()) }
    }

    private func fetchGPUUsage() async -> Int {
        await fetchMetric { Int(SystemStats.shared.getGPUUsage()) }
    }

    private func fetchRAMUsage() async -> Int {
        await fetchMetric { Int(SystemStats.shared.getRAMUsage()) }
    }

    private func fetchTemperature() async -> Double {
        SystemStats.shared.updateTemperatureAsync()
        return await fetchMetric { SystemStats.shared.getCPUTemperature() }
    }
}
