# Manual Test Steps for Matter Controller Daemon
## Step-by-Step Commands for End-to-End Testing

---

## 📋 Phase 1: Build-Time Validation

### **1.1 Clean Build Environment**

```bash
# Navigate to build directory
cd <your-build-directory>

# Clean build artifacts (optional, for clean test)
rm -rf tmp/work/cortexa72-rdk-linux/matter-controller-daemon/

# Source Yocto environment
source <yocto-setup-script>  # e.g., source poky/oe-init-build-env build
```

**Expected:** Clean environment, no errors

---

### **1.2 Recipe Parsing**

```bash
# Parse matter-controller-daemon recipe
bitbake -p matter-controller-daemon

# Check for parse errors
bitbake -e matter-controller-daemon | grep -i error
```

**Expected:** No parse errors

---

### **1.3 Verify SRC_URI Files Exist**

```bash
# Check matter-controller-daemon files
ls -la meta-rdk-matter/recipes-matter/matter-controller-daemon/files/
# Should show:
# - matter-controller-daemon.service
# - matter-controller-daemon/BUILD.gn
# - matter-controller-daemon/main.cpp
# - matter-controller-daemon/MatterController.h
# - matter-controller-daemon/MatterController.cpp
```

**Expected:** All source files present

---

### **1.4 Configure Stage**

```bash
# Configure matter-controller-daemon
bitbake -c configure matter-controller-daemon

# Check for configure errors
bitbake -c configure matter-controller-daemon 2>&1 | grep -i error
```

**Expected:** Configure completes without errors, BUILD.gn copied to SDK

---

### **1.5 Compile Stage**

```bash
# Compile matter-controller-daemon
bitbake -c compile matter-controller-daemon

# Check for compile errors
bitbake -c compile matter-controller-daemon 2>&1 | grep -i "error\|undefined reference"
```

**Expected:** Compile succeeds, binary created at:
`examples/matter-controller-daemon/out/aarch64/obj/examples/matter-controller-daemon/bin/matter-controller-daemon`

---

### **1.6 Package Stage**

```bash
# Package matter-controller-daemon
bitbake -c package matter-controller-daemon

# Check package contents
oe-pkgdata-util list-files matter-controller-daemon | grep -E "(matter-controller-daemon|\.service)"
```

**Expected:** Binary and systemd service file packaged

---

### **1.7 Image Build**

```bash
# Build complete image
bitbake <your-image-name>

# Verify package in image
oe-pkgdata-util list-pkgs | grep matter-controller-daemon
```

**Expected:** Image builds successfully, matter-controller-daemon included

---

## 📦 Phase 2: Installation Verification (On Target Device)

### **2.1 Flash Image and Boot**

```bash
# Flash image to SD card
# Boot target device (Raspberry Pi)
# SSH to target
ssh root@<target-ip>
```

**Expected:** Device boots successfully

---

### **2.2 Verify File Installation**

```bash
# Check binary
ls -la /usr/bin/matter-controller-daemon

# Check systemd service
ls -la /lib/systemd/system/matter-controller-daemon.service

# Verify binary is executable
stat -c "%a %n" /usr/bin/matter-controller-daemon
```

**Expected:** 
- Binary exists and is executable
- Service file exists with 644 permissions

---

### **2.3 Verify Storage Directory**

```bash
# Check storage directory (created by systemd service)
ls -la /var/lib/matter-controller/

# Check permissions
stat -c "%a %n" /var/lib/matter-controller/
```

**Expected:** Directory exists with 755 permissions (created on first service start)

---

## 🔄 Phase 3: Service Startup (On Target Device)

### **3.1 Check Service Registration**

```bash
# List service
systemctl list-unit-files | grep matter-controller-daemon

# Check service status (should be disabled by default)
systemctl status matter-controller-daemon.service
```

**Expected:** Service registered, status: inactive (dead) - disabled by default

---

### **3.2 Check Service Dependencies**

```bash
# Check service dependencies
systemctl show matter-controller-daemon.service | grep -E "(After|Requires|Wants)"

# Expected output:
# After=network-online.target avahi-daemon.service dbus.service ot-br-posix.service bluetooth.service
# Requires=avahi-daemon.service bluetooth.service
```

**Expected:** Dependencies configured correctly

---

### **3.3 Verify Prerequisites**

```bash
# Check BlueZ service
systemctl status bluetooth.service

# Check OTBR service
systemctl status ot-br-posix.service

# Check Avahi service
systemctl status avahi-daemon.service

# Check Thread interface
ip link show wpan0

# Check BlueZ adapter
bluetoothctl show
```

**Expected:** All prerequisite services active, wpan0 interface exists, BlueZ adapter powered

---

### **3.4 Start Service Manually**

```bash
# Enable service (optional - for auto-start on boot)
systemctl enable matter-controller-daemon.service

# Start service
systemctl start matter-controller-daemon.service

# Check status
systemctl status matter-controller-daemon.service
```

**Expected:** Service starts successfully, status: active (running)

---

### **3.5 Verify Service Logs**

```bash
# Check service logs
journalctl -u matter-controller-daemon.service -f

# Or view recent logs
journalctl -u matter-controller-daemon.service -n 50 --no-pager
```

**Expected Log Output:**
```
Matter Controller Daemon starting...
Initializing Matter Controller...
Created storage directory: /var/lib/matter-controller
Initializing CHIP stack...
CHIP stack initialized successfully
Initializing BLE...
BLE initialized and advertising enabled (always-on for commissioning)
Initializing Thread/OTBR...
Thread/OTBR initialized (wpan0 interface)
Opening commissioning window at startup...
Opening commissioning window...
BLE advertising enabled - controller ready to commission devices
Matter Controller initialized successfully
Matter Controller daemon running...
```

---

## 🔌 Phase 4: Runtime Functionality (On Target Device)

### **4.1 Verify Storage Persistence**

```bash
# Check storage files created
ls -la /var/lib/matter-controller/

# Should see:
# - chip_kvs (Key-Value Store for fabrics and credentials)
# - Possibly chip_factory.ini and chip_config.ini

# Check file permissions
stat -c "%a %n" /var/lib/matter-controller/chip_kvs
```

**Expected:** Storage files created, readable/writable

---

### **4.2 Verify BLE Advertising**

```bash
# Check BLE adapter state
hciconfig hci0

# Check if BLE is advertising
bluetoothctl scan on
# Wait 5-10 seconds, should see Matter commissioning advertisements

# Check BLE advertising in logs
journalctl -u matter-controller-daemon.service | grep -i "BLE\|advertising"
```

**Expected:** 
- BLE adapter UP and RUNNING
- Matter commissioning advertisements visible
- Logs show "BLE initialized and advertising enabled"

---

### **4.3 Verify Thread Integration**

```bash
# Check Thread interface
ip link show wpan0

# Check Thread state via OTBR
ot-ctl state

# Check if Thread is enabled in logs
journalctl -u matter-controller-daemon.service | grep -i "Thread\|OTBR"
```

**Expected:**
- wpan0 interface exists
- Thread network active (via OTBR)
- Logs show "Thread/OTBR initialized (wpan0 interface)"

---

### **4.4 Verify Commissioning Window**

```bash
# Check logs for commissioning window opening
journalctl -u matter-controller-daemon.service | grep -i "commissioning window\|QR Code"

# Expected output should show:
# - "Opening commissioning window at startup..."
# - "Opening commissioning window..."
# - QR Code (if generated)
# - Manual Pairing Code (if generated)
```

**Expected:** Commissioning window opened, QR code and pairing code logged

---

### **4.5 Verify Controller Functionality - Commission a Device**

```bash
# Ensure controller is running
systemctl status matter-controller-daemon.service

# Use chip-tool to commission a device (if available)
# Or use Matter mobile app to commission a device

# After commissioning, check storage for fabric
ls -la /var/lib/matter-controller/
# chip_kvs should have grown in size (fabric stored)

# Check logs for commissioning activity
journalctl -u matter-controller-daemon.service | grep -i "commission\|fabric"
```

**Expected:** 
- Device can be commissioned
- Fabric stored in chip_kvs
- Logs show commissioning activity

---

### **4.6 Verify Multi-Admin Support**

```bash
# Check if commissioning window can be reopened
# This would require adding a control interface or signal handler
# For now, verify the service can be restarted and window reopens

# Restart service
systemctl restart matter-controller-daemon.service

# Check logs for commissioning window reopening
journalctl -u matter-controller-daemon.service -n 30 | grep -i "commissioning window"
```

**Expected:** Service restarts, commissioning window reopens on startup

---

### **4.7 Verify Fabric Persistence**

```bash
# Commission a device (if not already done)
# Stop the service
systemctl stop matter-controller-daemon.service

# Check storage file size
ls -lh /var/lib/matter-controller/chip_kvs

# Restart service
systemctl start matter-controller-daemon.service

# Wait a few seconds
sleep 5

# Check if fabrics are still present (would need controller API to list fabrics)
# For now, verify service starts successfully with existing storage
journalctl -u matter-controller-daemon.service -n 20
```

**Expected:** 
- Storage file persists across restarts
- Service starts successfully with existing storage
- No errors about missing or corrupted storage

---

## 🔄 Phase 5: Event Loop and Stability

### **5.1 Verify Event Loop**

```bash
# Check if service is running continuously
systemctl status matter-controller-daemon.service

# Monitor for 1 minute
watch -n 5 'systemctl status matter-controller-daemon.service | head -10'

# Check process
ps aux | grep matter-controller-daemon
```

**Expected:** Service remains active (running), process continues running

---

### **5.2 Verify Graceful Shutdown**

```bash
# Stop service gracefully
systemctl stop matter-controller-daemon.service

# Check logs for shutdown
journalctl -u matter-controller-daemon.service -n 20 | grep -i "shutdown\|stopped"

# Expected output:
# "Received signal 15, shutting down..."
# "Shutting down Matter Controller..."
# "Matter Controller shut down gracefully"
# "Matter Controller Daemon stopped"
```

**Expected:** Service shuts down gracefully, logs show clean shutdown

---

### **5.3 Verify Restart Behavior**

```bash
# Restart service
systemctl restart matter-controller-daemon.service

# Check logs for initialization
journalctl -u matter-controller-daemon.service -n 30

# Verify storage is still accessible
ls -la /var/lib/matter-controller/chip_kvs
```

**Expected:** 
- Service restarts successfully
- Storage persists
- Commissioning window reopens

---

## 🧪 Phase 6: Integration Testing

### **6.1 Test with chip-tool (if available)**

```bash
# Ensure matter-controller-daemon is running
systemctl status matter-controller-daemon.service

# Use chip-tool to discover devices
chip-tool pairing onnetwork 1 20202021

# Check if both can coexist
ps aux | grep -E "(matter-controller-daemon|chip-tool)"
```

**Expected:** Both can run simultaneously (if needed)

---

### **6.2 Test BLE Commissioning Flow**

```bash
# Ensure BLE advertising is active
bluetoothctl scan on
# Should see Matter advertisements

# Use Matter mobile app or chip-tool to commission via BLE
# Monitor logs
journalctl -u matter-controller-daemon.service -f
```

**Expected:** BLE commissioning works, logs show activity

---

### **6.3 Test Thread Commissioning Flow**

```bash
# Ensure Thread network is active
ot-ctl state
# Should show: leader or router

# Use chip-tool or Matter app to commission via Thread
chip-tool pairing onnetwork 1 20202021

# Monitor logs
journalctl -u matter-controller-daemon.service -f
```

**Expected:** Thread commissioning works, logs show activity

---

## 🐛 Troubleshooting Commands

### **Service Issues**

```bash
# Check service status
systemctl status matter-controller-daemon.service

# Check service logs
journalctl -u matter-controller-daemon.service -n 100 --no-pager

# Check for errors
journalctl -u matter-controller-daemon.service | grep -i error

# Check service dependencies
systemctl list-dependencies matter-controller-daemon.service
```

### **Storage Issues**

```bash
# Check storage directory
ls -la /var/lib/matter-controller/

# Check storage file
file /var/lib/matter-controller/chip_kvs
ls -lh /var/lib/matter-controller/chip_kvs

# Check permissions
stat /var/lib/matter-controller/

# Try to create test file
touch /var/lib/matter-controller/test && rm /var/lib/matter-controller/test
```

### **BLE Issues**

```bash
# Check BlueZ service
systemctl status bluetooth.service

# Check BLE adapter
hciconfig hci0
bluetoothctl show

# Check BLE advertising
bluetoothctl scan on
# Wait 5 seconds, should see Matter advertisements

# Check logs for BLE errors
journalctl -u matter-controller-daemon.service | grep -i "BLE\|bluetooth\|error"
```

### **Thread Issues**

```bash
# Check OTBR service
systemctl status ot-br-posix.service

# Check Thread interface
ip link show wpan0

# Check Thread state
ot-ctl state

# Check logs for Thread errors
journalctl -u matter-controller-daemon.service | grep -i "Thread\|OTBR\|wpan0\|error"
```

### **Commissioning Issues**

```bash
# Check if commissioning window is open
journalctl -u matter-controller-daemon.service | grep -i "commissioning window"

# Check QR code generation
journalctl -u matter-controller-daemon.service | grep -i "QR Code"

# Check for commissioning errors
journalctl -u matter-controller-daemon.service | grep -i "commission\|error"
```

---

## ✅ Success Criteria Checklist

### **Phase 1: Build**
- [ ] Recipe parses successfully
- [ ] Configure completes without errors
- [ ] Compile succeeds (no errors)
- [ ] Binary created at correct location
- [ ] Image builds successfully

### **Phase 2: Installation**
- [ ] Binary installed correctly
- [ ] Systemd service file installed
- [ ] Storage directory created on first start

### **Phase 3: Services**
- [ ] Service registered
- [ ] Service starts successfully
- [ ] Dependencies satisfied
- [ ] Logs show successful initialization

### **Phase 4: Runtime**
- [ ] Storage files created
- [ ] BLE advertising active
- [ ] Thread integration working
- [ ] Commissioning window opens on startup
- [ ] Controller can commission devices
- [ ] Fabrics persist across restarts

### **Phase 5: Stability**
- [ ] Event loop runs continuously
- [ ] Graceful shutdown works
- [ ] Service restarts successfully
- [ ] Storage persists across restarts

### **Phase 6: Integration**
- [ ] BLE commissioning works
- [ ] Thread commissioning works
- [ ] Multi-admin support (if implemented)

---

## 📝 Quick Test Commands

### **Start and Monitor**

```bash
# Start service
systemctl start matter-controller-daemon.service

# Monitor logs in real-time
journalctl -u matter-controller-daemon.service -f
```

### **Check Status**

```bash
# Quick status check
systemctl status matter-controller-daemon.service

# Check if running
ps aux | grep matter-controller-daemon | grep -v grep

# Check storage
ls -lh /var/lib/matter-controller/
```

### **Stop and Restart**

```bash
# Stop service
systemctl stop matter-controller-daemon.service

# Restart service
systemctl restart matter-controller-daemon.service

# Check logs after restart
journalctl -u matter-controller-daemon.service -n 30
```

---

## 📝 Test Results Template

```
Test Date: _______________
Tester: _______________
Build Environment: _______________
Target Device: _______________
Matter SDK Version: _______________

Phase 1: Build-Time Validation
- 1.1 Clean Build: [PASS/FAIL]
- 1.2 Recipe Parsing: [PASS/FAIL]
- 1.3 SRC_URI Files: [PASS/FAIL]
- 1.4 Configure: [PASS/FAIL]
- 1.5 Compile: [PASS/FAIL]
- 1.6 Package: [PASS/FAIL]
- 1.7 Image Build: [PASS/FAIL]

Phase 2: Installation Verification
- 2.1 Flash Image: [PASS/FAIL]
- 2.2 File Installation: [PASS/FAIL]
- 2.3 Storage Directory: [PASS/FAIL]

Phase 3: Service Startup
- 3.1 Service Registration: [PASS/FAIL]
- 3.2 Service Dependencies: [PASS/FAIL]
- 3.3 Prerequisites: [PASS/FAIL]
- 3.4 Service Start: [PASS/FAIL]
- 3.5 Service Logs: [PASS/FAIL]

Phase 4: Runtime Functionality
- 4.1 Storage Persistence: [PASS/FAIL]
- 4.2 BLE Advertising: [PASS/FAIL]
- 4.3 Thread Integration: [PASS/FAIL]
- 4.4 Commissioning Window: [PASS/FAIL]
- 4.5 Controller Functionality: [PASS/FAIL]
- 4.6 Multi-Admin Support: [PASS/FAIL]
- 4.7 Fabric Persistence: [PASS/FAIL]

Phase 5: Stability
- 5.1 Event Loop: [PASS/FAIL]
- 5.2 Graceful Shutdown: [PASS/FAIL]
- 5.3 Restart Behavior: [PASS/FAIL]

Phase 6: Integration
- 6.1 chip-tool Coexistence: [PASS/FAIL]
- 6.2 BLE Commissioning: [PASS/FAIL]
- 6.3 Thread Commissioning: [PASS/FAIL]

Overall Status: [PASS/FAIL]
Critical Issues: _______________
Recommendations: _______________

Notes:
- Storage Location: /var/lib/matter-controller/chip_kvs
- Service: matter-controller-daemon.service
- Binary: /usr/bin/matter-controller-daemon
- Logs: journalctl -u matter-controller-daemon.service
```

---

## 🎯 Key Test Scenarios

### **Scenario 1: First Boot**

```bash
# Fresh install, first boot
systemctl start matter-controller-daemon.service
journalctl -u matter-controller-daemon.service -n 50

# Verify:
# - Storage directory created
# - CHIP stack initialized
# - BLE advertising enabled
# - Commissioning window opened
```

### **Scenario 2: After Commissioning Device**

```bash
# Commission a device using Matter app or chip-tool
# Then check:
ls -lh /var/lib/matter-controller/chip_kvs
journalctl -u matter-controller-daemon.service | grep -i fabric

# Verify:
# - Storage file size increased
# - Fabric stored
```

### **Scenario 3: Service Restart**

```bash
# Restart service
systemctl restart matter-controller-daemon.service

# Verify:
# - Service restarts successfully
# - Storage persists
# - Commissioning window reopens
# - BLE advertising resumes
```

### **Scenario 4: System Reboot**

```bash
# Reboot system
reboot

# After reboot, check:
systemctl status matter-controller-daemon.service
ls -la /var/lib/matter-controller/chip_kvs

# Verify:
# - Service starts on boot (if enabled)
# - Storage persists across reboot
# - Fabrics still available
```

---

## 🔍 Detailed Verification Commands

### **Verify CHIP Stack Initialization**

```bash
journalctl -u matter-controller-daemon.service | grep -i "CHIP stack\|Platform Manager\|initialized"
```

**Expected:** "CHIP stack initialized successfully"

### **Verify BLE Initialization**

```bash
journalctl -u matter-controller-daemon.service | grep -i "BLE\|advertising"
hciconfig hci0
bluetoothctl show
```

**Expected:** BLE initialized, advertising enabled, adapter powered

### **Verify Thread Initialization**

```bash
journalctl -u matter-controller-daemon.service | grep -i "Thread\|OTBR\|wpan0"
ip link show wpan0
ot-ctl state
```

**Expected:** Thread initialized, wpan0 interface exists, Thread network active

### **Verify Commissioning Window**

```bash
journalctl -u matter-controller-daemon.service | grep -i "commissioning window\|QR Code\|Pairing Code"
```

**Expected:** Commissioning window opened, QR code and pairing code logged

### **Verify Storage**

```bash
# Check storage file
file /var/lib/matter-controller/chip_kvs
ls -lh /var/lib/matter-controller/chip_kvs

# Check if it's being written to
watch -n 2 'ls -lh /var/lib/matter-controller/chip_kvs'
```

**Expected:** Storage file exists, size may increase when fabrics are added

---

## 🚨 Common Issues and Solutions

### **Issue: Service fails to start**

```bash
# Check logs
journalctl -u matter-controller-daemon.service -n 50

# Common causes:
# - BlueZ not ready (wait and retry)
# - wpan0 not available (check OTBR)
# - Storage directory permissions (check /var/lib/matter-controller/)
```

### **Issue: BLE advertising not working**

```bash
# Check BlueZ
systemctl status bluetooth.service
bluetoothctl show

# Check adapter
hciconfig hci0

# Check logs
journalctl -u matter-controller-daemon.service | grep -i "BLE\|error"
```

### **Issue: Thread not working**

```bash
# Check OTBR
systemctl status ot-br-posix.service

# Check interface
ip link show wpan0

# Check Thread state
ot-ctl state
```

### **Issue: Storage not persisting**

```bash
# Check permissions
stat /var/lib/matter-controller/
stat /var/lib/matter-controller/chip_kvs

# Check if directory exists
ls -la /var/lib/matter-controller/

# Check logs for storage errors
journalctl -u matter-controller-daemon.service | grep -i "storage\|kvs\|error"
```

---

## 📊 Performance Monitoring

### **Monitor Resource Usage**

```bash
# Check CPU usage
top -p $(pgrep matter-controller-daemon)

# Check memory usage
ps aux | grep matter-controller-daemon | grep -v grep

# Check file descriptors
lsof -p $(pgrep matter-controller-daemon) | wc -l
```

### **Monitor Logs Continuously**

```bash
# Follow logs
journalctl -u matter-controller-daemon.service -f

# Filter for errors
journalctl -u matter-controller-daemon.service -f | grep -i error

# Filter for commissioning
journalctl -u matter-controller-daemon.service -f | grep -i commission
```

---

## ✅ Final Verification Checklist

Before considering the test complete, verify:

- [ ] Service starts successfully
- [ ] No errors in logs
- [ ] BLE advertising active
- [ ] Thread integration working
- [ ] Commissioning window opens
- [ ] Storage directory created
- [ ] Can commission a device
- [ ] Fabrics persist across restart
- [ ] Service shuts down gracefully
- [ ] Service restarts successfully

---

**Test Document Version:** 1.0  
**Last Updated:** 2025-01-21  
**Target:** matter-controller-daemon v1.0
