# Developer Setup Guide

## Quick Start

### First Time Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Trio-GarminWatchface
   ```

2. **Run the setup script** (Recommended)
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   
   OR manually create your configuration:
   
   ```bash
   cp ConfigExample.local Config.local
   # Edit Config.local with your settings
   ```

3. **Verify your configuration**
   ```bash
   make show-config
   ```

4. **Build and run**
   ```bash
   make build    # Build the app
   make run      # Build and run in simulator
   make help     # See all available commands
   ```

## Configuration Files

### `Config.local` (Your personal settings - NOT in git)
This file contains your personal development settings:
- SDK path
- Preferred device
- Developer key location
- Deploy path

### `ConfigOverride.local` (Additional overrides - NOT in git)
Optional file for additional overrides that take precedence over Config.local.

### `properties.mk` (Shared defaults - IN git)
Contains default settings that work for most developers. Your Config.local overrides these.

### `ConfigExample.local` (Template - IN git)
Template showing all available settings with examples for different operating systems.

## Common Settings

### SDK Path Examples
- **macOS**: `/Users/YourName/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.3.0-2025-09-22-5813687a0`
- **Windows**: `C:/Users/YourName/AppData/Roaming/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.3.0`
- **Linux**: `/home/yourname/garmin/connectiq-sdk-linux-8.3.0`

### Popular Devices
- `fenix7`, `fenix6`, `fenix5xplus`
- `enduro3`, `enduro`
- `epix2`, `epixpro51mm`
- `venu3`, `venu2`
- `forerunner965`, `forerunner955`
- `edge1040`, `edge840`

## Useful Make Commands

### Building
- `make build` - Build for your default device
- `make buildall` - Build for all supported devices
- `make release` - Build optimized release version
- `make debug` - Build with debug symbols

### Testing
- `make run` - Build and run in simulator
- `make sim` - Just start the simulator
- `make test` - Run unit tests
- `make check` - Run type checking

### Distribution
- `make package` - Create .iq file for Connect IQ Store
- `make deploy` - Copy to your connected Garmin device

### Development
- `make clean` - Remove all build artifacts
- `make devices` - List all supported devices
- `make validate` - Check manifest for issues
- `make show-config` - Show current configuration

## Troubleshooting

### SDK Not Found
If you get "SDK not found" warning:
1. Check that Connect IQ SDK is installed
2. Update `SDK_HOME` in `Config.local` with correct path
3. Run `make show-config` to verify

### Simulator Won't Start
If simulator doesn't connect:
1. Make sure no other simulator is running
2. Try `make clean` then `make run`
3. Manually start simulator with `make sim`, then `make install`

### Device Not Supported
If your device isn't recognized:
1. Check device name with `make devices`
2. Ensure device is listed in `manifest.xml`
3. Update Connect IQ SDK to latest version

## Adding New Developers

When a new developer joins:
1. They clone the repository
2. Run `./setup.sh` or copy `ConfigExample.local` to `Config.local`
3. Update `Config.local` with their paths
4. Start developing!

No need to modify any shared files or worry about merge conflicts!

## Priority Order

Configuration settings are loaded in this order (later overrides earlier):
1. `properties.mk` defaults
2. `Config.local` (your main config)
3. `ConfigOverride.local` (optional additional overrides)
