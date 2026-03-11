# Manual CLI Test Steps
## Step-by-Step Commands for End-to-End Testing

---

## 📋 Phase 1: Build-Time Validation

### **1.1 Clean Build Environment**

```bash
# Navigate to build directory
cd <your-build-directory>

# Clean build artifacts
rm -rf build/ tmp/ cache/ sstate-cache/

# Source Yocto environment
source <yocto-setup-script>  # e.g., source poky/oe-init-build-env build
```

**Expected:** Clean environment, no errors

---

### **1.2 Recipe Parsing**

```bash
# Parse BlueZ recipe
bitbake -p bluez5

# Parse chip-tool recipe
bitbake -p chip-tool

# Check for parse errors
bitbake -e bluez5 | grep -i error
bitbake -e chip-tool | grep -i error
```

**Expected:** No parse errors

---

### **1.3 Verify SRC_URI Files Exist**

```bash
# Check BlueZ files
ls -la meta-rdk-matter/recipes-connectivity/bluez5/files/
# Should show:
# - default-bluetooth.conf
# - configure-ble-params.sh
# - ble-params.service
# - bluetooth.service

# Check chip-tool files
ls -la meta-rdk-matter/recipes-matter/chip-tool/files/
# Should show:
# - matter-commission.sh
# - verify-ble-ready.sh
# - chip-tool.service
```

**Expected:** All files present

---

### **1.4 Configure Stage**

```bash
# Configure BlueZ
bitbake -c configure bluez5

# Check for configure errors
bitbake -c configure bluez5 2>&1 | grep -i error

# Configure chip-tool
bitbake -c configure chip-tool

# Check for configure errors
bitbake -c configure chip-tool 2>&1 | grep -i error
```

**Expected:** Configure completes without errors

---

### **1.5 Compile Stage**

```bash
# Compile BlueZ
bitbake -c compile bluez5

# Check for compile errors
bitbake -c compile bluez5 2>&1 | grep -i "error\|undefined reference"

# Compile chip-tool
bitbake -c compile chip-tool

# Check for compile errors
bitbake -c compile chip-tool 2>&1 | grep -i "error\|undefined reference"
```

**Expected:** Compile succeeds, no errors

---

### **1.6 Package Stage**

```bash
# Package BlueZ
bitbake -c package bluez5

# Check package contents
oe-pkgdata-util list-files bluez5 | grep -E "(configure-ble-params|ble-params.service|main.conf)"

# Package chip-tool
bitbake -c package chip-tool

# Check package contents
oe-pkgdata-util list-files chip-tool | grep -E "(matter-commission|verify-ble-ready)"
```

**Expected:** All files packaged correctly

---

### **1.7 QA Stage**

```bash
# Run QA checks for BlueZ
bitbake -c checkpkg bluez5

# Check for specific QA issues
bitbake -c checkpkg bluez5 2>&1 | grep -i "file-rdeps\|host-user-contaminated\|missing.*dependency"

# Run QA checks for chip-tool
bitbake -c checkpkg chip-tool

# Check for specific QA issues
bitbake -c checkpkg chip-tool 2>&1 | grep -i "file-rdeps\|host-user-contaminated\|missing.*dependency"
```

**Expected:** No file-rdeps, host-user-contaminated, or missing dependency errors

---

### **1.8 Image Build**

```bash
# Build complete image
bitbake <your-image-name>

# Verify packages in image
oe-pkgdata-util list-pkgs | grep -E "(bluez5|chip-tool)"
```

**Expected:** Image builds successfully, packages included

---

## 📦 Phase 2: Installation Verification (On Target Device)

### **2.1 Flash Image and Boot**

```bash
# Flash image to SD card (method depends on your setup)
# Boot target device
# SSH to target
ssh root@<target-ip>
```

**Expected:** Device boots successfully

---

### **2.2 Verify File Installation**

```bash
# Check BlueZ files
ls -la /etc/bluetooth/main.conf
ls -la /usr/bin/configure-ble-params
ls -la /lib/systemd/system/bluetooth.service
ls -la /lib/systemd/system/ble-params.service

# Check chip-tool files
ls -la /usr/bin/chip-tool
ls -la /usr/bin/matter-commission
ls -la /usr/bin/verify-ble-ready
ls -la /lib/systemd/system/chip-tool.service
```

**Expected:** All files exist

---

### **2.3 Verify File Permissions**

```bash
# Check script permissions
stat -c "%a %n" /usr/bin/configure-ble-params
stat -c "%a %n" /usr/bin/matter-commission
stat -c "%a %n" /usr/bin/verify-ble-ready

# Check config permissions
stat -c "%a %n" /etc/bluetooth/main.conf
```

**Expected:** Scripts: 755, Configs: 644

---

### **2.4 Verify BlueZ Configuration**

```bash
# Check BlueZ main.conf values
cat /etc/bluetooth/main.conf | grep -E "(ConnectionTimeout|PageTimeout|AutoConnect|Experimental|Cache)"

# Expected output should show:
# ConnectionTimeout = 120
# PageTimeout = 20000
# AutoConnect = false
# Experimental = true
# Cache = always
```

**Expected:** All Phase 1 configuration values present

---

## 🔄 Phase 3: Service Startup (On Target Device)

### **3.1 Check Service Registration**

```bash
# List all services
systemctl list-unit-files | grep -E "(bluetooth|ble-params|chip-tool)"

# Check service status
systemctl status bluetooth.service
systemctl status ble-params.service
systemctl status chip-tool.service
```

**Expected:** All services registered, bluetooth and ble-params active

---

### **3.2 Check Service Dependencies**

```bash
# Check ble-params.service dependencies
systemctl show ble-params.service | grep -E "(After|Requires|Wants)"

# Check chip-tool.service dependencies
systemctl show chip-tool.service | grep -E "(After|Requires|Wants)"
```

**Expected:** 
- ble-params.service: After=bluetooth.service
- chip-tool.service: After=bluetooth.service

---

### **3.3 Verify Service Startup on Boot**

```bash
# Reboot device
reboot

# After reboot, check services
systemctl status bluetooth.service
systemctl status ble-params.service
systemctl status chip-tool.service

# Check service logs
journalctl -u bluetooth.service --since "1 hour ago" | head -20
journalctl -u ble-params.service --since "1 hour ago" | head -20
```

**Expected:** 
- bluetooth.service: active (running)
- ble-params.service: active (exited) or active (running)
- chip-tool.service: inactive (disabled) - expected

---

## 🔌 Phase 4: Runtime Functionality (On Target Device)

### **4.1 BlueZ Adapter Initialization**

```bash
# Check BlueZ service
systemctl status bluetooth.service

# Check adapter exists
hciconfig

# Check adapter state
hciconfig hci0

# Check adapter powered on
bluetoothctl show
```

**Expected:** 
- hci0 adapter present
- Adapter UP and RUNNING
- Adapter powered on

---

### **4.2 BLE Parameter Configuration**

```bash
# Run configure-ble-params script
configure-ble-params

# Verify connection parameters
hciconfig hci0 | grep -E "(connmin|connmax|connlat|connto)"

# Expected output should show:
# connmin 30 connmax 30 connlat 2 connto 10000
```

**Expected:** Script executes successfully, parameters set correctly

---

### **4.3 BLE Readiness Verification**

```bash
# Run verify-ble-ready script
verify-ble-ready

# Check exit code
echo $?

# Expected: Exit code 0
```

**Expected:** Script exits with code 0, all checks pass

---

### **4.4 Matter Commissioning Script - Basic Functionality**

```bash
# Test help output
matter-commission.sh help

# Test argument validation (should fail without Thread network)
matter-commission.sh thread-ble 1 12345678 3840
matter-commission.sh thread-ble 1 10579366 3856 
/usr/bin/matter-commission thread-ble 1 10579366 3856

```

**Expected:** 
- Help output shows all commands
- Script validates arguments and shows error if Thread network not started

---

### **4.5 Matter Commissioning - Retry Logic (Phase 1)**

```bash
ot-ctl dataset init new
ot-ctl dataset commit active
ot-ctl ifconfig up
ot-ctl thread start

# Wait for Thread to start
sleep 10

# Check Thread state
ot-ctl state

# Get Thread dataset
ot-ctl dataset active -x

# Save dataset for commissioning
DATASET=$(ot-ctl dataset active -x 2>/dev/null | grep -v "Done" | tr -d '\n' | tr -d ' ')
echo "Dataset: $DATASET"

# Attempt commissioning with retry logic
# Replace <PIN> and <DISCRIMINATOR> with actual device values
matter-commission.sh thread-ble 1 <PIN> <DISCRIMINATOR>

# Monitor output for:
# - Retry attempts
# - BlueZ state reset messages
# - Exponential backoff delays
# - Success or failure
```

**Expected:** 
- If first attempt fails, retry logic activates
- BlueZ state reset between retries
- Exponential backoff (500ms, 1000ms, 2000ms)
- Clear retry attempt messages

---

### **4.6 Error 36 Detection and Handling**

```bash
# Run commissioning and capture output
matter-commission.sh thread-ble 1 <PIN> <DISCRIMINATOR> 2>&1 | tee commissioning.log

# Check for error 36
grep -i "error.*36\|le-connection-abort-by-local\|connection-abort" commissioning.log

# Check if retry logic was triggered
grep -i "retry attempt" commissioning.log

# Check if BlueZ state reset was performed
grep -i "resetting bluez adapter state" commissioning.log

# Check for exponential backoff
grep -i "waiting.*ms before retry" commissioning.log
```

**Expected:** 
- Error 36 detected in logs (if it occurs)
- Retry logic activates on error 36
- BlueZ state reset performed
- Exponential backoff implemented

---

## 🔄 Phase 5: Regression Testing (On Target Device)

### **5.1 Thread Network Functionality**

```bash
# Check Thread state
ot-ctl state

# Start Thread network
ot-ctl thread start

# Wait and check state
sleep 3
ot-ctl state

# Get dataset
ot-ctl dataset active -x

# Check router table
ot-ctl router table

# Check child table
ot-ctl child table
```

**Expected:** Thread network starts and operates normally

---

### **5.2 Matter On-Network Commissioning**

```bash
# Ensure Thread network is active
ot-ctl state

# Test on-network commissioning (replace <PIN> with actual device PIN)
matter-commission.sh thread-onnetwork 1 <PIN>
```

**Expected:** On-network commissioning works (if device supports it)

---

### **5.3 Wi-Fi Commissioning**

```bash
# Check Wi-Fi interface
ip link show wlan0

# Check Wi-Fi IP
ip addr show wlan0 | grep "inet "

# Test Wi-Fi commissioning (replace <PIN> with actual device PIN)
matter-commission.sh wifi 2 <PIN>
```

**Expected:** Wi-Fi commissioning works (if device supports it)

---

## 🐛 Troubleshooting Commands

### **Build Issues**

```bash
# Check recipe syntax
bitbake -p bluez5 2>&1 | grep -i error

# Check dependencies
bitbake -e bluez5 | grep ^DEPENDS
bitbake -e bluez5 | grep ^RDEPENDS

# Check file paths
find meta-rdk-matter -name "default-bluetooth.conf"
find meta-rdk-matter -name "configure-ble-params.sh"
```

### **Runtime Issues**

```bash
# Check BlueZ service
systemctl status bluetooth.service
journalctl -u bluetooth.service -n 50

# Check kernel modules
lsmod | grep -E "(bluetooth|hci_uart|btbcm)"

# Check adapter
hciconfig hci0
bluetoothctl show

# Check /sys/class/bluetooth
ls -la /sys/class/bluetooth/

# Run readiness check
verify-ble-ready
```

### **Commissioning Issues**

```bash
# Check Thread network
ot-ctl state
ot-ctl dataset active -x

# Check BLE adapter
hciconfig hci0
bluetoothctl show

# Check commissioning logs
matter-commission.sh thread-ble 1 <PIN> <DISCRIMINATOR> 2>&1 | tee commissioning.log
cat commissioning.log | grep -i error
```

---

## ✅ Success Criteria Checklist

### **Phase 1: Build**
- [ ] All recipes parse successfully
- [ ] Configure completes without errors
- [ ] Compile succeeds (no errors)
- [ ] QA checks pass (no file-rdeps, no host-user-contaminated)
- [ ] Image builds successfully

### **Phase 2: Installation**
- [ ] All files installed correctly
- [ ] Scripts executable (755)
- [ ] Configs readable (644)
- [ ] BlueZ configuration values correct

### **Phase 3: Services**
- [ ] All services registered
- [ ] bluetooth.service active
- [ ] ble-params.service active/exited
- [ ] Dependencies correct

### **Phase 4: Runtime**
- [ ] BlueZ adapter UP and RUNNING
- [ ] Connection parameters set correctly
- [ ] BLE readiness check passes
- [ ] Commissioning script works
- [ ] Retry logic activates on failure
- [ ] Error 36 handled correctly

### **Phase 5: Regression**
- [ ] Thread network works
- [ ] On-network commissioning works
- [ ] Wi-Fi commissioning works

---

## 📝 Test Results Template

```
Test Date: _______________
Tester: _______________
Build Environment: _______________
Target Device: _______________

Phase 1: Build-Time Validation
- 1.1 Clean Build: [PASS/FAIL]
- 1.2 Recipe Parsing: [PASS/FAIL]
- 1.3 SRC_URI Files: [PASS/FAIL]
- 1.4 Configure: [PASS/FAIL]
- 1.5 Compile: [PASS/FAIL]
- 1.6 Package: [PASS/FAIL]
- 1.7 QA: [PASS/FAIL]
- 1.8 Image Build: [PASS/FAIL]

Phase 2: Installation Verification
- 2.1 Flash Image: [PASS/FAIL]
- 2.2 File Installation: [PASS/FAIL]
- 2.3 File Permissions: [PASS/FAIL]
- 2.4 BlueZ Configuration: [PASS/FAIL]

Phase 3: Service Startup
- 3.1 Service Registration: [PASS/FAIL]
- 3.2 Service Dependencies: [PASS/FAIL]
- 3.3 Service Startup on Boot: [PASS/FAIL]

Phase 4: Runtime Functionality
- 4.1 BlueZ Adapter: [PASS/FAIL]
- 4.2 BLE Parameters: [PASS/FAIL]
- 4.3 BLE Readiness: [PASS/FAIL]
- 4.4 Commissioning Script: [PASS/FAIL]
- 4.5 Retry Logic: [PASS/FAIL]
- 4.6 Error 36 Handling: [PASS/FAIL]

Phase 5: Regression Testing
- 5.1 Thread Network: [PASS/FAIL]
- 5.2 On-Network Commissioning: [PASS/FAIL]
- 5.3 Wi-Fi Commissioning: [PASS/FAIL]

Overall Status: [PASS/FAIL]
Critical Issues: _______________
Recommendations: _______________
```

---

## 🎯 Quick Reference

**Build Machine:**
- Phase 1: All commands in "Phase 1" section

**Target Device:**
- Phase 2-5: All commands in "Phase 2-5" sections

**Replace Placeholders:**
- `<PIN>` - Device PIN code (e.g., 10579366)
- `<DISCRIMINATOR>` - Device discriminator (e.g., 3856)
- `<target-ip>` - Target device IP address
- `<your-image-name>` - Your Yocto image name
- `<yocto-setup-script>` - Path to Yocto setup script

---

**All commands are ready to copy-paste and execute!**

