import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        observeStatsManager()
        observePreferences()
        PreferencesManager.shared.checkLaunchAtLoginStatus()
        StatsManager.shared.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        StatsManager.shared.stopMonitoring()
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.font = NSFont.monospacedDigitSystemFont(
                ofSize: UIConstants.StatusBar.fontSize,
                weight: UIConstants.StatusBar.fontWeight
            )
            button.action = #selector(togglePopover)
            button.target = self
            button.title = AppConstants.appName
        }
        Log.ui.debug("Status item initialized")
    }

    // MARK: - Stats Observation

    private func observeStatsManager() {
        StatsManager.shared.$currentMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateStatusText(with: metrics)
            }
            .store(in: &cancellables)
    }

    private func observePreferences() {
        let prefs = PreferencesManager.shared

        Publishers.CombineLatest4(
            prefs.$showCPU,
            prefs.$showGPU,
            prefs.$showRAM,
            prefs.$showTemperature
        )
        .combineLatest(prefs.$temperatureUnit)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateStatusText(with: StatsManager.shared.currentMetrics)
        }
        .store(in: &cancellables)
    }

    private func updateStatusText(with metrics: SystemMetrics) {
        guard let button = statusItem?.button else { return }

        let prefs = PreferencesManager.shared
        let attributed = NSMutableAttributedString()

        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]

        var isFirst = true

        for statType in StatType.allCases {
            guard statType.isEnabled(in: prefs) else { continue }

            if !isFirst {
                attributed.append(NSAttributedString(string: UIConstants.StatusBar.statSeparator, attributes: textAttributes))
            }

            appendIcon(statType.icon, to: attributed)

            let valueString: String
            if statType == .temperature {
                valueString = metrics.temperatureString(unit: prefs.temperatureUnit)
            } else {
                valueString = statType.formattedValue(from: metrics)
            }

            attributed.append(NSAttributedString(string: valueString, attributes: textAttributes))
            isFirst = false
        }

        if attributed.length == 0 {
            button.attributedTitle = NSAttributedString(string: AppConstants.appName, attributes: textAttributes)
        } else {
            button.attributedTitle = attributed
        }
    }

    private func appendIcon(_ symbolName: String, to attributed: NSMutableAttributedString) {
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(
                pointSize: UIConstants.StatusBar.iconPointSize,
                weight: UIConstants.StatusBar.iconWeight
            )
            let configuredImage = image.withSymbolConfiguration(config) ?? image
            let attachment = NSTextAttachment()
            attachment.image = configuredImage
            attributed.append(NSAttributedString(attachment: attachment))
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(
            width: UIConstants.Popover.width,
            height: UIConstants.Popover.height
        )
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        Log.ui.debug("Popover initialized")
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
