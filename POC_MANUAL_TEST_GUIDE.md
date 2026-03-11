# Matter POC Manual Test Guide
## Aqara LED Bulb T2 (Thread) Commissioning & Control

**Device Under Test:** Aqara LED Bulb T2 (LB-L03E) - Thread-only Matter device  
**Border Router:** Raspberry Pi 4 with RDK-B  
**Transport:** Matter over Thread

---

## 📋 Pre-Conditions

### Hardware Setup
- [ ] Raspberry Pi 4 powered on and booted
- [ ] Thread RCP device (e.g., nRF52840 dongle) connected via USB
- [ ] RCP device appears as `/dev/ttyACM0` (or known path)
- [ ] Aqara LED Bulb T2 (LB-L03E) powered on and in range
- [ ] Raspberry Pi 4 connected to network (Wi-Fi or Ethernet)
- [ ] SSH access to Raspberry Pi 4 available

### Software Setup
- [ ] RDK-B image with Matter integration flashed
- [ ] All services installed and available
- [ ] Root/sudo access on Raspberry Pi 4

### Verification Commands
```bash
# Verify RCP device
ls -l /dev/ttyACM0
# Expected: Device exists (e.g., crw-rw---- 1 root dialout 166, 0)

# Verify system
uname -a
# Expected: Linux system information

# Verify network
ip addr show
# Expected: Network interfaces with IP addresses
```

---

## 🔧 Phase 1: System Preparation

### Step 1.1: Verify Services Are Installed

**Command:**
```bash
systemctl list-unit-files | grep -E "ot-br-posix|chip-lighting|avahi"
```

**Expected Result:**
```
ot-br-posix.service                    enabled         enabled
chip-lighting-app.service              disabled        disabled
avahi-daemon.service                   enabled         enabled
```

**Verification:** All services listed (enabled/disabled status OK)

---

### Step 1.2: Verify Helper Tools Available

**Command:**
```bash
which chip-tool
which matter-commission
which get-thread-dataset
which ot-ctl
```

**Expected Result:**
```
/usr/bin/chip-tool
/usr/bin/matter-commission
/usr/bin/get-thread-dataset
/usr/sbin/ot-ctl
```

**Verification:** All commands found

---

### Step 1.3: Check Kernel Modules

**Command:**
```bash
lsmod | grep -E "mac802154|ieee802154|tun"
```

**Expected Result:**
```
mac802154             12345  0
ieee802154            23456  2 mac802154
tun                   34567  1
```

**If modules not loaded, load them:**
```bash
modprobe mac802154
modprobe ieee802154
modprobe tun
```

**Verification:** All three modules loaded (or can be loaded)

---

### Step 1.4: Verify RCP Device Access

**Command:**
```bash
ls -l /dev/ttyACM0
```

**Expected Result:**
```
crw-rw---- 1 root dialout 166, 0 Dec 23 12:00 /dev/ttyACM0
```

**If permissions issue, fix:**
```bash
chmod 666 /dev/ttyACM0
```

**Verification:** Device exists and is accessible

---

## 🌐 Phase 2: Thread Border Router Setup

### Step 2.1: Start OpenThread Border Router Service

**Command:**
```bash
systemctl start ot-br-posix.service
```

**Expected Result:**
- Command completes without error
- No immediate error message

**Verification:** Command returns to prompt

---

### Step 2.2: Check Service Status

**Command:**
```bash
systemctl status ot-br-posix.service
```

**Expected Result:**
```
● ot-br-posix.service - OpenThread Border Router
     Loaded: loaded (/lib/systemd/system/ot-br-posix.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-12-23 12:05:00 UTC; 10s ago
   Main PID: 12345 (otbr-agent-wrapper)
      Tasks: 2 (limit: 3857)
```

**Verification:** Service shows `active (running)`

**If service failed:**
```bash
journalctl -u ot-br-posix.service -n 50 --no-pager
```

---

### Step 2.3: Verify otbr-agent Process

**Command:**
```bash
ps aux | grep otbr-agent | grep -v grep
```

**Expected Result:**
```
root      12345  0.5  1.2  /usr/sbin/otbr-agent -I wpan0 -B br0 -d 7 spinel+hdlc+uart:///dev/ttyACM0
```

**Verification:** otbr-agent process running

---

### Step 2.4: Wait for wpan0 Interface Creation

**Command:**
```bash
ip link show wpan0
```

**Expected Result (initially):**
```
Device "wpan0" does not exist.
```

**Wait and check again (repeat every 10 seconds, up to 60 seconds):**
```bash
# Wait 10 seconds
sleep 10
ip link show wpan0
```

**Expected Result (after 15-60 seconds):**
```
3: wpan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 300
    link/ieee802.15.4 
```

**Verification:** wpan0 interface exists

**If wpan0 doesn't appear after 60 seconds:**
```bash
# Check logs
journalctl -u ot-br-posix.service -n 100 | tail -30
cat /tmp/otbr-agent.log
```

---

### Step 2.5: Verify wpan0 Interface Details

**Command:**
```bash
ip link show wpan0
ip addr show wpan0
```

**Expected Result:**
```
3: wpan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 300
    link/ieee802.15.4 
    inet6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
```

**Verification:** Interface shows IEEE 802.15.4 type and has IPv6 address

---

### Step 2.6: Start Thread Network

**Command:**
```bash
ot-ctl thread start
```

**Expected Result:**
```
Done
```

**Verification:** Command returns "Done"

---

### Step 2.7: Check Thread Network State

**Command:**
```bash
ot-ctl state
```

**Expected Result:**
```
detached
```
or
```
child
```
or
```
router
```
or
```
leader
```

**Verification:** State shows Thread network is active (not "disabled")

**If state is "detached", start again:**
```bash
ot-ctl ifconfig up
ot-ctl thread start
sleep 3
ot-ctl state
```

---

### Step 2.8: Get Thread Operational Dataset

**Command:**
```bash
get-thread-dataset.sh
```

**Expected Result:**
```
Getting OpenThread operational dataset...

Operational Dataset (hex):
0e080000000000010000000300000f35060004001fffe0020811111111222222220708fd1234567890abcdef0510...

Use this for BLE-Thread commissioning:
chip-tool pairing ble-thread <NODE_ID> hex:0e080000... <PIN_CODE> <DISCRIMINATOR>
```

**Alternative (manual method):**
```bash
ot-ctl dataset active -x
```

**Expected Result:** Hex string (operational dataset)

**Verification:** Operational dataset retrieved (copy the hex string)

**Note:** Save this dataset - you'll need it for commissioning

---

## 📱 Phase 3: Matter App Setup

### Step 3.1: Start Matter Lighting App

**Command:**
```bash
systemctl start chip-lighting-app.service
```

**Expected Result:**
- Command completes without error

**Verification:** Command returns to prompt

---

### Step 3.2: Verify Matter App Status

**Command:**
```bash
systemctl status chip-lighting-app.service
```

**Expected Result:**
```
● chip-lighting-app.service - Chip Lighting App for Matter IoT
     Loaded: loaded (/lib/systemd/system/chip-lighting-app.service; disabled; vendor preset: disabled)
     Active: active (running) since Tue 2025-12-23 12:10:00 UTC; 5s ago
   Main PID: 23456 (chip-lighting-app)
```

**Verification:** Service shows `active (running)`

---

### Step 3.3: Check Matter App Logs

**Command:**
```bash
journalctl -u chip-lighting-app.service -n 20 --no-pager
```

**Expected Result:**
```
Dec 23 12:10:00 RaspberryPi-Gateway chip-lighting-app[23456]: CHIP:DL: Device is paired
Dec 23 12:10:00 RaspberryPi-Gateway chip-lighting-app[23456]: CHIP:DL: Thread interface enabled
Dec 23 12:10:00 RaspberryPi-Gateway chip-lighting-app[23456]: CHIP:DL: Matter app started
```

**Verification:** Logs show Matter app started and Thread enabled

---

### Step 3.4: Verify mDNS/Avahi Service

**Command:**
```bash
systemctl status avahi-daemon.service
```

**Expected Result:**
```
● avahi-daemon.service - Avahi mDNS/DNS-SD Stack
     Loaded: loaded (/lib/systemd/system/avahi-daemon.service; enabled; vendor preset: enabled)
     Active: active (running)
```

**Verification:** Avahi service is running

---

## 💡 Phase 4: Aqara Bulb Commissioning

### Step 4.1: Put Aqara Bulb in Pairing Mode

**Manual Action (on the bulb):**
1. Turn bulb OFF
2. Turn bulb ON
3. Repeat OFF/ON cycle 5 times quickly (within 2 seconds each)
4. Bulb LED should blink or change color pattern
5. Bulb stays in pairing mode for ~2 minutes

**Visual Indicator:** Bulb LED blinks or shows pairing pattern

**Verification:** Bulb is in pairing mode (LED indicator)

---

### Step 4.2: Get Aqara Bulb Pairing Information

**Required Information:**
- **PIN Code:** Typically found on bulb packaging or in Aqara app
- **Discriminator:** Usually 3840 for Aqara devices (check device manual)
- **Operational Dataset:** Already obtained in Step 2.8

**Note:** If you don't have PIN code, check:
- Bulb packaging/QR code
- Aqara Home app (if previously paired)
- Device manual

**Typical Aqara Values:**
- PIN Code: 8-digit number (e.g., 12345678)
- Discriminator: 3840 (common for Aqara)

**Verification:** You have PIN code and discriminator ready

---

### Step 4.3: Commission Bulb via BLE-Thread (Method 1 - Recommended)

**Command:**
```bash
# Replace <PIN_CODE> and <DISCRIMINATOR> with actual values
# Use operational dataset from Step 2.8
chip-tool pairing ble-thread 1 hex:<OPERATIONAL_DATASET> <PIN_CODE> <DISCRIMINATOR>
```

**Example:**
```bash
chip-tool pairing ble-thread 1 hex:0e080000000000010000000300000f35060004001fffe0020811111111222222220708fd1234567890abcdef0510... 12345678 3840
```

**Expected Result:**
```
[timestamp] CHIP:DL: BLE connection established
[timestamp] CHIP:DL: Operational credentials received
[timestamp] CHIP:DL: Device commissioned successfully
[timestamp] CHIP:DL: Device node ID: 1
```

**Verification:** Commissioning completes successfully

**If using helper script:**
```bash
matter-commission.sh thread-ble 1 <PIN_CODE> <DISCRIMINATOR>
```

---

### Step 4.4: Commission Bulb via OnNetwork (Method 2 - Alternative)

**Note:** Only if BLE-Thread method fails or device supports on-network commissioning

**Command:**
```bash
chip-tool pairing onnetwork 1 <PIN_CODE>
```

**Expected Result:**
```
[timestamp] CHIP:DL: Device discovered
[timestamp] CHIP:DL: Device commissioned successfully
[timestamp] CHIP:DL: Device node ID: 1
```

**Verification:** Commissioning completes successfully

---

### Step 4.5: Verify Device Commissioned

**Command:**
```bash
chip-tool pairing list
```

**Expected Result:**
```
Node ID: 1
  Fabric ID: 1
  Endpoint: 1
  Device Type: On/Off Light
  Vendor ID: 0x115F (Aqara)
  Product ID: 0xXXXX
```

**Verification:** Aqara bulb appears in pairing list with Node ID 1

---

## 🎮 Phase 5: Device Control

### Step 5.1: Turn Bulb ON

**Command:**
```bash
chip-tool onoff on 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Sending on/off command
[timestamp] CHIP:CTL: Command sent successfully
```

**Visual Verification:** 
- Bulb physically turns ON
- Bulb LED is lit

**Verification:** Both command success AND physical bulb response

---

### Step 5.2: Read Bulb State

**Command:**
```bash
chip-tool onoff read on-off 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Reading on/off attribute
OnOff: 1
```

**Verification:** State shows `1` (ON)

---

### Step 5.3: Turn Bulb OFF

**Command:**
```bash
chip-tool onoff off 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Sending on/off command
[timestamp] CHIP:CTL: Command sent successfully
```

**Visual Verification:**
- Bulb physically turns OFF
- Bulb LED is off

**Verification:** Both command success AND physical bulb response

---

### Step 5.4: Read Bulb State Again

**Command:**
```bash
chip-tool onoff read on-off 1 1
```

**Expected Result:**
```
OnOff: 0
```

**Verification:** State shows `0` (OFF)

---

### Step 5.5: Test Brightness Control (If Supported)

**Command:**
```bash
chip-tool levelcontrol move-to-level 128 0 0 0 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Brightness command sent
[timestamp] CHIP:CTL: Command sent successfully
```

**Visual Verification:** Bulb brightness changes to ~50% (128/255)

**Verification:** Bulb brightness changes

---

### Step 5.6: Test Color Temperature (CCT - If Supported)

**Command:**
```bash
chip-tool colorcontrol movetocolortemperature 370 0 0 0 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Color temperature command sent
[timestamp] CHIP:CTL: Command sent successfully
```

**Visual Verification:** Bulb color temperature changes (warm/cool white)

**Verification:** Bulb color temperature changes

---

## 🔄 Phase 6: Persistence Validation

### Step 6.1: Verify Current State

**Command:**
```bash
chip-tool pairing list
chip-tool onoff read on-off 1 1
```

**Expected Result:**
- Device still in pairing list
- Can read current state

**Verification:** Device accessible before reboot

---

### Step 6.2: Reboot System

**Command:**
```bash
reboot
```

**Expected Result:**
- System reboots
- Wait 2-3 minutes for system to come back up

**Verification:** System reboots successfully

---

### Step 6.3: After Reboot - Check Services

**Command:**
```bash
systemctl status ot-br-posix.service
systemctl status chip-lighting-app.service
```

**Expected Result:**
```
● ot-br-posix.service - OpenThread Border Router
     Active: active (running)

● chip-lighting-app.service - Chip Lighting App for Matter IoT
     Active: active (running)
```

**Verification:** Both services auto-started

---

### Step 6.4: After Reboot - Verify Thread Network

**Command:**
```bash
ip link show wpan0
ot-ctl state
```

**Expected Result:**
```
3: wpan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 ...
```
```
child
```
or
```
router
```
or
```
leader
```

**If Thread network not started:**
```bash
ot-ctl thread start
sleep 3
ot-ctl state
```

**Verification:** wpan0 exists and Thread network can start

---

### Step 6.5: After Reboot - Verify Device Still Commissioned

**Command:**
```bash
chip-tool pairing list
```

**Expected Result:**
```
Node ID: 1
  Fabric ID: 1
  Endpoint: 1
  Device Type: On/Off Light
```

**Verification:** Device still in pairing list (same Node ID)

---

### Step 6.6: After Reboot - Test Control

**Command:**
```bash
chip-tool onoff on 1 1
sleep 2
chip-tool onoff read on-off 1 1
```

**Expected Result:**
```
[timestamp] CHIP:CTL: Command sent successfully
OnOff: 1
```

**Visual Verification:** Bulb turns ON

**Verification:** Device control works after reboot

---

## 📱 Phase 7: Mobile Controller Commissioning (Alternative Method)

### Step 7.1: Prepare Mobile Device

**Requirements:**
- iOS device with iOS 16+ or Android device with Android 8+
- Matter-compatible app installed (e.g., Apple Home, Google Home, SmartThings)
- Mobile device on same Wi-Fi network as Raspberry Pi 4

**Verification:** Mobile device ready

---

### Step 7.2: Put Bulb in Pairing Mode

**Same as Step 4.1:**
- Power cycle bulb 5 times quickly
- Bulb LED should blink

**Verification:** Bulb in pairing mode

---

### Step 7.3: Scan QR Code or Enter Setup Code

**On Mobile Device:**
1. Open Matter-compatible app
2. Tap "Add Device" or "+"
3. Select "Matter" or "Thread" device
4. Scan QR code on bulb packaging OR
5. Enter 8-digit setup code (PIN code)

**Expected Result:**
- App discovers the bulb
- Shows device information

**Verification:** Device discovered in app

---

### Step 7.4: Complete Commissioning in App

**On Mobile Device:**
1. Follow app prompts to complete pairing
2. App may ask to connect to Thread network
3. Select the Thread network (should show Raspberry Pi 4 as border router)
4. Complete setup

**Expected Result:**
- App shows "Device added successfully"
- Bulb appears in device list
- Can control bulb from app

**Verification:** Bulb commissioned and controllable from mobile app

---

### Step 7.5: Verify from Raspberry Pi

**Command:**
```bash
chip-tool pairing list
```

**Expected Result:**
```
Node ID: 1
  Fabric ID: 1
  ...
```

**Note:** Node ID may be different if mobile app assigned different ID

**Verification:** Device appears in pairing list

---

### Step 7.6: Test Control from Both

**From Raspberry Pi:**
```bash
chip-tool onoff on 1 1
```

**From Mobile App:**
- Turn bulb OFF using app

**Expected Result:**
- Commands from both work
- Bulb responds to both controllers

**Verification:** Multi-controller control works

---

## ✅ Success Criteria

### Critical (Must Pass)

- [ ] **wpan0 Interface Created:** Interface appears within 60 seconds of service start
- [ ] **Thread Network Active:** `ot-ctl state` shows active state (child/router/leader)
- [ ] **Device Commissioned:** Aqara bulb appears in `chip-tool pairing list`
- [ ] **Device Control Works:** Can turn bulb ON/OFF via chip-tool commands
- [ ] **Physical Response:** Bulb physically responds to commands
- [ ] **Persistence:** Device remains commissioned after reboot
- [ ] **Post-Reboot Control:** Can control device after reboot

### Important (Should Pass)

- [ ] **Service Auto-Start:** Services start automatically after reboot
- [ ] **Thread Network Restores:** Thread network can start after reboot
- [ ] **Brightness Control:** Brightness commands work (if supported)
- [ ] **Color Temperature:** CCT commands work (if supported)

### Optional (Nice to Have)

- [ ] **Mobile App Commissioning:** Can commission via mobile app
- [ ] **Multi-Controller:** Multiple controllers can control same device
- [ ] **Multiple Devices:** Can commission multiple Thread devices

---

## 🔍 Troubleshooting Reference

### Issue: wpan0 Not Created

**Check:**
```bash
# Service status
systemctl status ot-br-posix.service

# Process running
pgrep -x otbr-agent

# Logs
journalctl -u ot-br-posix.service -n 50
cat /tmp/otbr-agent.log

# Kernel modules
lsmod | grep mac802154
```

**Fix:** See WPAN0_DIAGNOSTIC.md

---

### Issue: Thread Network Not Starting

**Check:**
```bash
# Thread state
ot-ctl state

# Interface
ip link show wpan0

# Start manually
ot-ctl ifconfig up
ot-ctl thread start
```

**Fix:** Ensure wpan0 exists and is UP

---

### Issue: Commissioning Fails

**Check:**
```bash
# Bulb in pairing mode (LED blinking)
# PIN code correct
# Discriminator correct
# Operational dataset valid

# Test with verbose output
chip-tool pairing ble-thread 1 hex:<DATASET> <PIN> <DISC> --verbose
```

**Fix:** Verify pairing information, ensure bulb in pairing mode

---

### Issue: Device Not Responding

**Check:**
```bash
# Device still in list
chip-tool pairing list

# Thread network active
ot-ctl state

# Bulb powered on
# Bulb in range
```

**Fix:** Ensure Thread network active, bulb powered, in range

---

## 📊 Test Results Log

### Test Execution

| Phase | Step | Status | Notes | Time |
|-------|------|--------|-------|------|
| **Phase 1: System Prep** |
| 1.1 | Services installed | ⬜ Pass / ⬜ Fail | | |
| 1.2 | Tools available | ⬜ Pass / ⬜ Fail | | |
| 1.3 | Kernel modules | ⬜ Pass / ⬜ Fail | | |
| 1.4 | RCP device | ⬜ Pass / ⬜ Fail | | |
| **Phase 2: Thread BR** |
| 2.1 | Start OTBR service | ⬜ Pass / ⬜ Fail | | |
| 2.2 | Service status | ⬜ Pass / ⬜ Fail | | |
| 2.3 | otbr-agent process | ⬜ Pass / ⬜ Fail | | |
| 2.4 | wpan0 created | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| 2.5 | wpan0 details | ⬜ Pass / ⬜ Fail | | |
| 2.6 | Thread network start | ⬜ Pass / ⬜ Fail | | |
| 2.7 | Thread state | ⬜ Pass / ⬜ Fail | | |
| 2.8 | Operational dataset | ⬜ Pass / ⬜ Fail | | |
| **Phase 3: Matter App** |
| 3.1 | Start Matter app | ⬜ Pass / ⬜ Fail | | |
| 3.2 | App status | ⬜ Pass / ⬜ Fail | | |
| 3.3 | App logs | ⬜ Pass / ⬜ Fail | | |
| 3.4 | mDNS service | ⬜ Pass / ⬜ Fail | | |
| **Phase 4: Commissioning** |
| 4.1 | Bulb pairing mode | ⬜ Pass / ⬜ Fail | | |
| 4.2 | Pairing info | ⬜ Pass / ⬜ Fail | | |
| 4.3 | Commission (BLE-Thread) | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| 4.4 | Commission (OnNetwork) | ⬜ Pass / ⬜ Fail | | |
| 4.5 | Verify commissioned | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| **Phase 5: Control** |
| 5.1 | Turn ON | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| 5.2 | Read state | ⬜ Pass / ⬜ Fail | | |
| 5.3 | Turn OFF | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| 5.4 | Read state | ⬜ Pass / ⬜ Fail | | |
| 5.5 | Brightness | ⬜ Pass / ⬜ Fail | | |
| 5.6 | Color temp | ⬜ Pass / ⬜ Fail | | |
| **Phase 6: Persistence** |
| 6.1 | Pre-reboot state | ⬜ Pass / ⬜ Fail | | |
| 6.2 | Reboot | ⬜ Pass / ⬜ Fail | | |
| 6.3 | Services after reboot | ⬜ Pass / ⬜ Fail | | |
| 6.4 | Thread after reboot | ⬜ Pass / ⬜ Fail | | |
| 6.5 | Device after reboot | ⬜ Pass / ⬜ Fail | **CRITICAL** | |
| 6.6 | Control after reboot | ⬜ Pass / ⬜ Fail | **CRITICAL** | |

### Overall Result
- **Total Steps:** 30+
- **Critical Steps Passed:** ___ / 7
- **Overall Status:** ⬜ Pass / ⬜ Fail

---

## 🎯 Quick Validation Checklist

**Minimum Viable Test (15 minutes):**

1. [ ] wpan0 created: `ip link show wpan0`
2. [ ] Thread network active: `ot-ctl state`
3. [ ] Device commissioned: `chip-tool pairing list`
4. [ ] Control works: `chip-tool onoff on 1 1` (bulb turns on)
5. [ ] After reboot: Device still works

**If all 5 pass, POC is successful!**

---

**Follow this guide step-by-step to validate your Matter POC!**

