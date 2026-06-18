import Foundation
import IOKit

// MARK: - SMC Structures

private struct SMCKeyData {
    struct Vers {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    struct LimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    struct KeyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    var key: UInt32 = 0
    var vers = Vers()
    var pLimitData = LimitData()
    var keyInfo = KeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

private let kSMCUserClientOpen: UInt32 = 0
private let kSMCUserClientClose: UInt32 = 1
private let kSMCHandleYieldKey: UInt32 = 2
private let kSMCReadKey: UInt8 = 5
private let kSMCGetKeyInfo: UInt8 = 9

class SystemStats {
    static let shared = SystemStats()

    private var previousCPUInfo: host_cpu_load_info?
    private var smcConnection: io_connect_t = 0
    private let hidReader = HIDTemperatureReader()

    private init() {
        openSMCConnection()
    }

    deinit {
        closeSMCConnection()
    }

    // MARK: - SMC Connection

    private func openSMCConnection() {
        // Try different SMC service names
        let serviceNames = ["AppleSMC", "AppleSMCFamily", "IOSMCMT"]

        for serviceName in serviceNames {
            let matchingDict = IOServiceMatching(serviceName)
            var iterator: io_iterator_t = 0

            guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
                continue
            }

            let service = IOIteratorNext(iterator)
            IOObjectRelease(iterator)

            guard service != 0 else { continue }

            // Try different user client types (0, 1, 2)
            for clientType: UInt32 in 0...2 {
                var connection: io_connect_t = 0
                let result = IOServiceOpen(service, mach_task_self_, clientType, &connection)
                if result == KERN_SUCCESS && connection != 0 {
                    smcConnection = connection
                    IOObjectRelease(service)
                    return
                }
            }

            IOObjectRelease(service)
        }
    }

    private func closeSMCConnection() {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
            smcConnection = 0
        }
    }

    // MARK: - SMC Reading

    private func fourCharCodeToUInt32(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for char in str.utf8.prefix(4) {
            result = (result << 8) | UInt32(char)
        }
        return result
    }

    private func readSMCKey(_ key: String) -> Double? {
        guard smcConnection != 0 else { return nil }

        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        let keyCode = fourCharCodeToUInt32(key)
        inputStruct.key = keyCode
        inputStruct.data8 = kSMCGetKeyInfo

        let inputSize = MemoryLayout<SMCKeyData>.size
        var outputSize = MemoryLayout<SMCKeyData>.size

        let result1 = IOConnectCallStructMethod(
            smcConnection,
            kSMCHandleYieldKey,
            &inputStruct,
            inputSize,
            &outputStruct,
            &outputSize
        )

        guard result1 == KERN_SUCCESS else { return nil }

        inputStruct.keyInfo.dataSize = outputStruct.keyInfo.dataSize
        inputStruct.keyInfo.dataType = outputStruct.keyInfo.dataType
        inputStruct.data8 = kSMCReadKey

        outputStruct = SMCKeyData()

        let result2 = IOConnectCallStructMethod(
            smcConnection,
            kSMCHandleYieldKey,
            &inputStruct,
            inputSize,
            &outputStruct,
            &outputSize
        )

        guard result2 == KERN_SUCCESS else { return nil }

        // Convert bytes to temperature based on data type
        let dataType = outputStruct.keyInfo.dataType
        let bytes = outputStruct.bytes
        let dataSize = outputStruct.keyInfo.dataSize

        // Handle flt (float) type - common on Apple Silicon
        if dataType == fourCharCodeToUInt32("flt ") && dataSize >= 4 {
            var floatValue: Float = 0
            withUnsafeMutableBytes(of: &floatValue) { ptr in
                ptr[0] = bytes.0
                ptr[1] = bytes.1
                ptr[2] = bytes.2
                ptr[3] = bytes.3
            }
            // Check endianness - try big endian if value seems wrong
            if floatValue < 0 || floatValue > 150 {
                withUnsafeMutableBytes(of: &floatValue) { ptr in
                    ptr[0] = bytes.3
                    ptr[1] = bytes.2
                    ptr[2] = bytes.1
                    ptr[3] = bytes.0
                }
            }
            return Double(floatValue)
        }

        // Handle sp78 (signed fixed-point 7.8) - common on Intel
        if dataType == fourCharCodeToUInt32("sp78") && dataSize >= 2 {
            let intValue = Int16(bytes.0) << 8 | Int16(bytes.1)
            return Double(intValue) / 256.0
        }

        // Handle fpe2 (unsigned fixed-point) type
        if dataType == fourCharCodeToUInt32("fpe2") && dataSize >= 2 {
            let intValue = UInt16(bytes.0) << 8 | UInt16(bytes.1)
            return Double(intValue) / 4.0
        }

        // Handle ui8 (unsigned int 8) type
        if dataType == fourCharCodeToUInt32("ui8 ") && dataSize >= 1 {
            return Double(bytes.0)
        }

        // Handle ui16 type
        if dataType == fourCharCodeToUInt32("ui16") && dataSize >= 2 {
            let intValue = UInt16(bytes.0) << 8 | UInt16(bytes.1)
            return Double(intValue)
        }

        return nil
    }

    // MARK: - Temperature

    private var cachedTemperature: Double = 0.0
    private var lastTemperatureUpdate: Date = .distantPast

    func getCPUTemperature() -> Double {
        // Return cached value if recent (async update happens in background)
        return cachedTemperature
    }

    func updateTemperatureAsync() {
        // Read on-die thermal sensors in-process — no helper, root, or entitlement.
        // HID sensors cover Apple Silicon; SMC keys are the Intel fallback.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }

            var temp = self.hidReader.readCPUTemperature()
            if !TemperatureConstants.isValid(temp) {
                temp = self.getSMCTemperature() ?? 0
            }

            guard TemperatureConstants.isValid(temp) else { return }
            DispatchQueue.main.async {
                self.cachedTemperature = temp
                self.lastTemperatureUpdate = Date()
            }
        }
    }

    private func getSMCTemperature() -> Double? {
        // Apple Silicon CPU temperature keys (M1/M2/M3)
        let appleSiliconKeys = [
            // CPU performance core temperatures
            "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0T", "Tp0X", "Tp0b",
            "Tp0f", "Tp0j", "Tp0n", "Tp0r",
            // CPU efficiency core temperatures
            "Tp02", "Tp06", "Tp0A", "Tp0E", "Tp0I", "Tp0M", "Tp0Q", "Tp0U", "Tp0Y", "Tp0c",
            // CPU proximity/die sensors
            "Tc0a", "Tc0b", "Tc0c", "Tc0d",
            "Tc1a", "Tc1b", "Tc1c", "Tc1d",
            // PMU sensors
            "Tp1h", "Tp1t", "Tp1p", "Tp1l",
            // SOC sensors
            "Ts0P", "Ts0S", "Ts1P", "Ts1S",
            // Other common M-series keys
            "Tw0P", "TW0P"
        ]

        // Intel temperature keys
        let intelKeys = [
            "TC0P", "TC0H", "TC0D", "TC0E", "TC0F",
            "TC1C", "TC2C", "TC3C", "TC4C", "TC5C", "TC6C", "TC7C", "TC8C",
            "TCAD", "TCGC", "TCSA", "TCTD",
            "TC0c", "TC0d"
        ]

        // Try Apple Silicon keys first
        for key in appleSiliconKeys {
            if let temp = readSMCKey(key), temp > 10 && temp < 120 {
                return temp
            }
        }

        // Try Intel keys
        for key in intelKeys {
            if let temp = readSMCKey(key), temp > 10 && temp < 120 {
                return temp
            }
        }

        return nil
    }

    // MARK: - CPU Usage

    func getCPUUsage() -> Double {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0.0
        }

        let currentUser = cpuLoadInfo.cpu_ticks.0
        let currentSystem = cpuLoadInfo.cpu_ticks.1
        let currentIdle = cpuLoadInfo.cpu_ticks.2
        let currentNice = cpuLoadInfo.cpu_ticks.3

        defer {
            previousCPUInfo = cpuLoadInfo
        }

        guard let previous = previousCPUInfo else {
            return 0.0
        }

        let previousUser = previous.cpu_ticks.0
        let previousSystem = previous.cpu_ticks.1
        let previousIdle = previous.cpu_ticks.2
        let previousNice = previous.cpu_ticks.3

        let userDelta = currentUser - previousUser
        let systemDelta = currentSystem - previousSystem
        let idleDelta = currentIdle - previousIdle
        let niceDelta = currentNice - previousNice

        let totalTicks = userDelta + systemDelta + idleDelta + niceDelta

        guard totalTicks > 0 else {
            return 0.0
        }

        let usedTicks = userDelta + systemDelta + niceDelta
        let cpuUsage = (Double(usedTicks) / Double(totalTicks)) * 100.0

        return cpuUsage
    }

    func getRAMUsage() -> Double {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0.0
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let totalRAM = UInt64(ProcessInfo.processInfo.physicalMemory)

        let activeMemory = UInt64(vmStats.active_count) * pageSize
        let wiredMemory = UInt64(vmStats.wire_count) * pageSize
        let compressedMemory = UInt64(vmStats.compressor_page_count) * pageSize

        let usedMemory = activeMemory + wiredMemory + compressedMemory
        let ramUsage = (Double(usedMemory) / Double(totalRAM)) * 100.0

        return ramUsage
    }

    func getGPUUsage() -> Double {
        // Try Apple Silicon GPU first (AGXAccelerator)
        if let usage = getAppleSiliconGPUUsage() {
            return usage
        }

        // Fallback to Intel GPU (IOAccelerator)
        if let usage = getIntelGPUUsage() {
            return usage
        }

        return 0.0
    }

    private func getAppleSiliconGPUUsage() -> Double? {
        let matchingDict = IOServiceMatching("AGXAccelerator")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return nil
        }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let props = properties?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            // Look for performance statistics
            if let perfStats = props["PerformanceStatistics"] as? [String: Any] {
                // Try different keys used by Apple Silicon GPUs
                if let utilization = perfStats["Device Utilization %"] as? Double {
                    return utilization
                }
                if let utilization = perfStats["GPU Activity(%)"] as? Double {
                    return utilization
                }
                if let utilization = perfStats["hardwareWaitTime"] as? Double,
                   let totalTime = perfStats["hardwareTotalTime"] as? Double,
                   totalTime > 0 {
                    return ((totalTime - utilization) / totalTime) * 100.0
                }
            }
        }

        return nil
    }

    private func getIntelGPUUsage() -> Double? {
        let matchingDict = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return nil
        }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let props = properties?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            if let perfStats = props["PerformanceStatistics"] as? [String: Any] {
                // Intel GPU utilization keys
                if let utilization = perfStats["GPU Core Utilization"] as? Double {
                    return utilization
                }
                if let utilization = perfStats["Device Utilization %"] as? Double {
                    return utilization
                }
            }
        }

        return nil
    }
}

// MARK: - Apple Silicon Thermal Sensors (IOHIDEventSystem)

/// Reads on-die temperature sensors via the IOHIDEventSystem API.
/// Runs fully unprivileged — no helper, root, or entitlement required.
final class HIDTemperatureReader {
    private let page = 0xff00            // kHIDPage_AppleVendor
    private let usage = 0x0005           // kHIDUsage_AppleVendor_TemperatureSensor
    private let eventTypeTemperature: Int64 = 15  // kIOHIDEventTypeTemperature
    private let temperatureField = Int32(15 << 16) // IOHIDEventFieldBase(temperature)

    /// CPU/SOC temperature in Celsius, or 0 if no sensor is available.
    func readCPUTemperature() -> Double {
        let sensors = readSensors()
        guard !sensors.isEmpty else { return 0 }

        // Prefer CPU/SoC die sensors; otherwise average everything we found.
        // Sensor names vary by Mac: "pACC/eACC MTR" on some, "PMU tdieN" on others.
        let cpu = sensors.filter { name, _ in
            let n = name.lowercased()
            return n.contains("die") || n.contains("cpu") || n.contains("soc")
                || n.hasPrefix("pacc") || n.hasPrefix("eacc")
        }.map { $0.value }

        let pool = cpu.isEmpty ? Array(sensors.values) : cpu
        return pool.reduce(0, +) / Double(pool.count)
    }

    private func readSensors() -> [String: Double] {
        guard let system = IOHIDEventSystemClientCreate(kCFAllocatorDefault)?.takeRetainedValue() else {
            return [:]
        }

        let matching = ["PrimaryUsagePage": page, "PrimaryUsage": usage] as CFDictionary
        IOHIDEventSystemClientSetMatching(system, matching)

        guard let services = IOHIDEventSystemClientCopyServices(system) as? [IOHIDServiceClient] else {
            return [:]
        }

        var sensors: [String: Double] = [:]
        for service in services {
            guard let event = IOHIDServiceClientCopyEvent(service, eventTypeTemperature, 0, 0)?.takeRetainedValue() else {
                continue
            }
            let value = IOHIDEventGetFloatValue(event, temperatureField)
            guard TemperatureConstants.isValid(value) else { continue }

            let name = (IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String) ?? ""
            sensors[name.isEmpty ? "sensor\(sensors.count)" : name] = value
        }
        return sensors
    }
}
