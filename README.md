# MiStats

[![CI](https://github.com/jzucadi/SysStats/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/jzucadi/SysStats/actions/workflows/objective-c-xcode.yml)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<img width="522" height="37" alt="Screenshot 2026-06-18 at 2 24 50 PM" src="https://github.com/user-attachments/assets/5296d6a6-2510-4c25-a28a-ae401527f434" />

The only system stat app you will ever need.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Building from Source](#building-from-source)
- [Usage](#usage)
- [Architecture](#architecture)
- [Distribution](#distribution)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Menu bar only** - No dock icon, no main window, stays out of your way
- **Real-time monitoring** - Displays CPU, GPU, RAM usage and temperature
- **Icon-based display** - Uses SF Symbols for a clean, native look
- **Configurable refresh rate** - Choose between 1s, 2s, or 5s update intervals
- **SwiftUI popover** - Click for detailed stats with color-coded progress bars
- **Preferences panel** - Customize which stats to show, temperature unit, and more
- **Launch at login** - Optional auto-start when you log in
- **Apple Silicon support** - Optimized for M1/M2/M3 Macs with IOKit thermal sensors
- **Low resource usage** - Minimal CPU and memory footprint

## Screenshots

### Menu Bar Display

<img width="200" height="65" alt="sys-stats-small-pic" src="https://github.com/user-attachments/assets/5f5912dc-83e1-489f-90f5-b1d3f5dba23c" />

The menu bar shows real-time system metrics in a compact format:

| Icon | Metric |
|------|--------|
| 🖥️ | CPU usage percentage |
| 🧊 | GPU usage percentage |
| 💾 | RAM usage percentage |
| 🌡️ | Temperature (°C or °F) |

### Popover Details

Click the menu bar item to see:
- Detailed stats with progress bars
- Color-coded usage levels (green/yellow/red)
- Gear icon to access preferences
- Quit button

### Preferences

Access preferences via the gear icon in the popover:

- **Update Interval** - 1s, 2s, or 5s refresh rate
- **Show in Menu Bar** - Toggle CPU, GPU, RAM, Temperature visibility
- **Temperature Unit** - Celsius (°C) or Fahrenheit (°F)
- **Launch at Login** - Start automatically on login

## Requirements

- **macOS 13.0 (Ventura) or later**
- **Apple Silicon (M1/M2/M3) or Intel Mac** - Temperature monitoring works best on Apple Silicon
- **Xcode 15.0+** (for building from source)

## Installation

### Option 1: Download Pre-built Binary (Recommended)

1. Download the latest release DMG from the [Releases](https://github.com/jzucadi/SysStats/releases) page
2. Open the DMG file
3. Drag `SysStats.app` to your Applications folder
4. Launch SysStats from Applications — it appears in the menu bar right away

### Option 2: Build from Source

See [Building from Source](#building-from-source) section below.

## Building from Source

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- A valid Apple Developer account (for code signing)

### Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jzucadi/SysStats.git
   cd SysStats
   ```

2. **Open in Xcode:**
   ```bash
   open SysStats.xcodeproj
   ```

3. **Configure code signing:**
   - Select the SysStats project in Xcode
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Ensure "Automatically manage signing" is enabled

4. **Build and run:**
   - Press `⌘R` or select Product → Run
   - The app will launch in your menu bar

### Building for Release

For a release build with optimizations:

```bash
# Build release version
./scripts/build-release.sh 1.0

# Create distributable DMG
./scripts/create-dmg.sh 1.0
```

The built app will be in `build/Build/Products/Release/` and the DMG in `dist/`.

## Usage

### First Launch

1. Launch SysStats from Applications or the menu bar
2. The stats appear immediately — no permissions, helper install, or admin password required

### Menu Bar

The stats appear in your menu bar in the format: `C:45% G:12% R:67% 42°`

Click the menu bar item to:
- View detailed stats with visual progress bars
- Access preferences (gear icon)
- Quit the application

### Customization

Click the gear icon in the popover to customize:
- Which metrics to display
- Update frequency (1s, 2s, or 5s)
- Temperature unit (Celsius or Fahrenheit)
- Launch at login behavior

## Architecture

SysStats is built with modern Swift and SwiftUI, using the following architecture:

| Component | Description |
|-----------|-------------|
| `SysStatsApp` | SwiftUI app entry point |
| `AppDelegate` | Status bar setup and Combine observation pipeline |
| `StatsManager` | Async metrics fetching with configurable update intervals |
| `SystemStats` | Low-level IOKit-based CPU, GPU, RAM, and temperature reading |
| `HIDTemperatureReader` | Reads on-die thermal sensors via IOHIDEventSystem — no privileges required |
| `PreferencesManager` | UserDefaults-backed settings storage with @Published properties |
| `ContentView` | SwiftUI popover interface with real-time updates |

### Key Technologies

- **SwiftUI** - Modern declarative UI framework
- **Combine** - Reactive programming for state management
- **IOKit** - Low-level system information access
- **IOHIDEventSystem** - On-die thermal sensor data on Apple Silicon
- **SMC (System Management Controller)** - Temperature fallback on Intel Macs
- **SMAppService** - Launch-at-login registration

### Temperature Monitoring

Temperature is read entirely in-process — **no privileged helper, root access, or
special entitlement required**:

- **Apple Silicon:** the `IOHIDEventSystem` API enumerates the SoC's thermal
  sensors (CPU/SoC die) and averages the relevant ones.
- **Intel:** falls back to reading SMC temperature keys directly.

This uses Apple's private `IOHIDEventSystemClient` API, which is permitted for
Developer ID / direct distribution (the Mac App Store is the only channel that
forbids private API). Because the app is not sandboxed, these sensors are
readable without any user permission prompt.

## Distribution

### Signing and Notarization

For public distribution, your app must be signed and notarized by Apple:

1. **Sign the app with Developer ID:**
   ```bash
   codesign --force --verify --verbose \
     --sign "Developer ID Application: Your Name (TEAM_ID)" \
     --options runtime \
     dist/SysStats.app
   ```
   The app is a single bundle with no embedded helper, so no `--deep` is needed.

2. **Create a signed DMG:**
   ```bash
   ./scripts/create-dmg.sh 1.0
   codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
     dist/SysStats-1.0.dmg
   ```

3. **Notarize with Apple:**
   ```bash
   xcrun notarytool submit dist/SysStats-1.0.dmg \
     --apple-id your@email.com \
     --team-id TEAM_ID \
     --password APP_SPECIFIC_PASSWORD \
     --wait
   ```

4. **Staple the notarization:**
   ```bash
   xcrun stapler staple dist/SysStats-1.0.dmg
   ```

### Hardened Runtime

The app is configured with Hardened Runtime for enhanced security. The only entitlement it declares (`SysStats.entitlements`) is `com.apple.security.app-sandbox = false`, which is required for direct IOKit/HID/SMC sensor access. No additional hardened-runtime exceptions are needed.

**Note:** Temperature works in development builds too — there is no privileged helper to install or sign. A Developer ID and notarization are only needed so that *other* users can run the app without Gatekeeper warnings.

## Troubleshooting

### Temperature shows "—°" or is not updating

**Cause:** No readable thermal sensors were found (rare), or you're on an Intel Mac where SMC keys differ by model.

**Solution:**
- Confirm the app is **not** sandboxed (the shipped `SysStats.entitlements` sets `app-sandbox = false`); sandboxing blocks IOKit/HID sensor access
- Restart the app
- Check Console.app (subsystem `com.jameszaccardo.SysStats`, category `temperature`) for read errors

### App doesn't show in menu bar

**Cause:** The app may have crashed or failed to launch.

**Solution:**
- Check Activity Monitor for the SysStats process
- Look for crash logs in Console.app
- Try deleting preferences: `defaults delete com.jameszaccardo.SysStats`
- Rebuild and reinstall the app

### Stats show 0% or incorrect values

**Cause:** Permissions issue or IOKit access problem.

**Solution:**
- Grant all requested permissions in System Settings → Privacy & Security
- Restart the app after granting permissions
- Check Console.app for error messages related to IOKit

### App won't launch after installation

**Cause:** macOS Gatekeeper blocking unsigned or unnotarized app.

**Solution:**
- Right-click the app and select "Open"
- Or run: `xattr -cr /Applications/SysStats.app`
- For release builds, ensure proper signing and notarization

### High CPU usage

**Cause:** Update interval set too low or system monitoring overhead.

**Solution:**
- Increase update interval to 2s or 5s in preferences
- Reduce the number of displayed metrics
- Check for other system monitoring tools that may conflict

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

- Use the [GitHub Issues](https://github.com/jzucadi/SysStats/issues) page
- Include macOS version, Mac model, and steps to reproduce
- Attach relevant logs from Console.app if applicable

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes following the existing code style
4. Test thoroughly on your local machine
5. Commit with clear, descriptive messages
6. Push to your fork and submit a pull request

### Development Guidelines

- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Keep the app lightweight and performant
- Maintain compatibility with macOS 13.0+
- Add comments for complex logic
- Test on both Apple Silicon and Intel Macs if possible

### Code Style

- Use 4 spaces for indentation
- Follow existing naming conventions
- Group related code with `// MARK:` comments
- Keep functions focused and concise

## License

MIT

Copyright (c) 2026 SysStats Contributors

See the [LICENSE](LICENSE) file for full license text.

## Acknowledgments

- Built with Swift and SwiftUI
- Uses IOKit framework for system information
- Temperature monitoring inspired by various SMC monitoring tools
- Icons provided by SF Symbols
