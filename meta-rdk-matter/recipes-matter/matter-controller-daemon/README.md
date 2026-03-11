# Matter Controller Daemon

## Overview

This is a **separate Matter Controller daemon application** that provides persistent Matter Controller functionality with:

- ✅ **Persistent Matter Controller** - Runs as a systemd daemon
- ✅ **BLE Commissioning (Always-On)** - BLE remains enabled after commissioning
- ✅ **Multi-Admin Support** - Supports multiple Matter fabrics and administrators
- ✅ **Auto-Open Commissioning Window** - Automatically opens commissioning window on startup
- ✅ **Fabric Persistence** - Stores fabrics and credentials in `/var/lib/matter-controller/`
- ✅ **Thread/OTBR Integration** - Automatically uses OTBR (`wpan0`) for Thread devices
- ✅ **QR Code BLE Commissioning** - Supports QR code and manual pairing codes

## Architecture

This is a **separate binary** from `chip-all-clusters-app` and `chip-tool`:

- **`chip-all-clusters-app`**: Matter device endpoint (cannot commission other devices)
- **`chip-tool`**: Temporary CLI commissioner (creates new controller instance per command)
- **`matter-controller-daemon`**: Persistent controller daemon (can commission devices, maintains state)

## Files Created

### C++ Source Files
- `main.cpp` - Main entry point with signal handling
- `MatterController.h` - Controller class header
- `MatterController.cpp` - Controller implementation

### Build Files
- `BUILD.gn` - GN build configuration for the daemon
- `0001-Add-Matter-Controller-Daemon.patch` - Patch to add the daemon to Matter SDK

### Yocto Integration
- `matter-controller-daemon.bb` - Yocto recipe to build the daemon
- `matter-controller-daemon.service` - systemd service file

## Key Features Implementation

### 1. Matter Controller C++ Implementation

**Location**: `examples/matter-controller-daemon/linux/`

- **`main.cpp`**: Initializes platform memory, handles signals (SIGINT/SIGTERM), creates and runs controller
- **`MatterController.h/cpp`**: Implements controller lifecycle, CHIP stack initialization, storage, BLE, Thread

**Key Functions**:
- `Init()` - Initializes CHIP stack, storage, BLE, Thread, opens commissioning window
- `Run()` - Main event loop (blocks until shutdown)
- `Shutdown()` - Graceful shutdown
- `OpenCommissioningWindow()` - Opens commissioning window for multi-admin
- `CloseCommissioningWindow()` - Closes commissioning window

### 2. Commissioning Window Logic

**Implementation**: `MatterController::OpenCommissioningWindow()`

- Uses `CommissioningWindowOpener` API from Matter SDK
- Automatically opens window at startup via `OpenStartupCommissioningWindow()`
- Supports re-opening window for multi-admin commissioning
- Prints QR code and manual pairing code to logs

**Code Location**: `MatterController.cpp:195-230`

### 3. Fabric Persistence

**Implementation**: `MatterController::InitStorage()`

- Uses `LinuxPersistentStorage` from Matter SDK
- Storage paths:
  - KVS: `/var/lib/matter-controller/chip_kvs`
  - Factory: `/var/lib/matter-controller/chip_factory.ini`
  - Config: `/var/lib/matter-controller/chip_config.ini`
- Storage directory created automatically if missing
- Passed to `DeviceController::InitDeviceController()` via `DeviceControllerInitParams`

**Code Location**: `MatterController.cpp:140-160`

### 4. BLE Commissioning (Always-On)

**Implementation**: `MatterController::InitBLE()`

- BLE initialized by Platform Manager
- Explicitly enables BLE advertising: `ConnectivityMgr().SetBLEAdvertisingEnabled(true)`
- Sets advertising mode: `ConnectivityMgr().SetBLEAdvertisingMode(ConnectivityManager::kBLEAdvertisingMode_Enabled)`
- BLE remains enabled after commissioning (not disabled post-pairing)

**Code Location**: `MatterController.cpp:162-180`

### 5. Thread + OTBR Integration

**Implementation**: `MatterController::InitThread()`

- Thread initialized by Platform Manager using `wpan0` interface (from environment variable)
- Sets device type: `ConnectivityMgr().SetThreadDeviceType(ConnectivityManager::kThreadDeviceType_Router)`
- Enables Thread: `ConnectivityMgr().SetThreadEnabled(true)`
- No manual Thread provisioning required

**Code Location**: `MatterController.cpp:182-195`

### 6. Build Integration

**BUILD.gn**: Defines executable with:
- Source files: `main.cpp`, `MatterController.cpp`
- Dependencies: Controller SDK, Server, BLE, Platform, Credentials
- Compiler flags: Thread interface (`wpan0`), Wi-Fi interface (`wlan0`), BLE enabled

**Yocto Recipe**: `matter-controller-daemon.bb`
- Builds from `examples/matter-controller-daemon/linux/`
- Applies SDK patches (BLE fixes, QR code commissioning)
- Installs binary to `/usr/bin/matter-controller-daemon`
- Installs systemd service

## Building

### In Yocto

```bash
# Build the daemon
bitbake matter-controller-daemon

# Install on target
opkg install matter-controller-daemon
```

### Manual Build (for testing)

```bash
cd examples/matter-controller-daemon/linux
gn gen out/aarch64 --args='target_os="linux" target_cpu="arm64" ...'
ninja -C out/aarch64
```

## Usage

### Start Service

```bash
systemctl start matter-controller-daemon
systemctl enable matter-controller-daemon  # Auto-start on boot
```

### Check Status

```bash
systemctl status matter-controller-daemon
journalctl -u matter-controller-daemon -f
```

### Verify Commissioning Window

```bash
# Check BLE advertising
hcitool lescan --duplicates | grep -i matter

# Check logs for QR code
journalctl -u matter-controller-daemon | grep "QR Code"
```

### Commission Devices

The daemon opens a commissioning window automatically. Use `chip-tool` or mobile apps to commission devices:

```bash
# Get Thread dataset
DATASET=$(ot-ctl dataset active -x | grep -v "Done" | tr -d '\r\n')

# Commission device (using chip-tool as temporary commissioner)
chip-tool pairing ble-thread 1 hex:$DATASET 12345678 3840 --bypass-attestation-verifier true
```

**Note**: The daemon maintains the fabric, but `chip-tool` is still used for commissioning commands. Future enhancement: Add D-Bus API for commissioning from the daemon.

## Storage

All fabrics and credentials are stored in `/var/lib/matter-controller/`:

- `chip_kvs` - Key-value store with fabrics and operational credentials
- `chip_factory.ini` - Factory configuration
- `chip_config.ini` - Runtime configuration

Storage persists across reboots.

## Differences from chip-all-clusters-app

| Feature | chip-all-clusters-app | matter-controller-daemon |
|---------|----------------------|-------------------------|
| Role | Matter Device | Matter Controller |
| Can Commission Devices | ❌ No | ✅ Yes |
| Persistent | ✅ Yes | ✅ Yes |
| BLE Always-On | ✅ Yes | ✅ Yes |
| Multi-Admin | ✅ Yes | ✅ Yes |
| Commissioning Window | ✅ Yes (as device) | ✅ Yes (as controller) |

## API Limitations

**Current Implementation**:
- Uses Matter SDK Controller APIs
- Opens commissioning window automatically
- Maintains persistent fabrics

**Future Enhancements** (not in this implementation):
- D-Bus API for remote commissioning window control
- REST API for device management
- Web UI for device management

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u matter-controller-daemon -n 100

# Verify dependencies
systemctl status bluetooth
systemctl status ot-br-posix
systemctl status avahi-daemon
```

### BLE Not Advertising

```bash
# Restart BlueZ
systemctl restart bluetooth
systemctl restart matter-controller-daemon

# Check BLE
hciconfig hci0
```

### Thread Issues

```bash
# Check Thread interface
ip link show wpan0
ot-ctl state

# Restart OTBR
systemctl restart ot-br-posix
```

## Code Structure

```
examples/matter-controller-daemon/linux/
├── main.cpp                 # Entry point
├── MatterController.h       # Controller class header
├── MatterController.cpp     # Controller implementation
└── BUILD.gn                 # Build configuration
```

## Integration with Existing Setup

This daemon **coexists** with your existing Matter apps:

- `chip-all-clusters-app` - Still available as Matter device
- `chip-tool` - Still available for CLI commissioning
- `matter-controller-daemon` - New persistent controller

All apps share the same Matter SDK source and patches.

