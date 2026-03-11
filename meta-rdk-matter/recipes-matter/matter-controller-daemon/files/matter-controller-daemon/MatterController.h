/*
 * Copyright (c) 2025
 * SPDX-License-Identifier: Apache-2.0
 *
 * Matter Controller Daemon - Controller Class Header
 * Persistent Matter Controller with BLE Commissioning and Multi-Admin Support
 */

#pragma once

#include <lib/core/CHIPError.h>
#include <lib/support/CHIPMem.h>
#include <platform/CHIPDeviceLayer.h>
#include <controller/CommissioningWindowOpener.h>
#include <controller/CHIPDeviceController.h>
#include <platform/PlatformManager.h>
#include <platform/ConnectivityManager.h>
#include <platform/KeyValueStoreManager.h>
#include <platform/Linux/CHIPLinuxStorage.h>
#include <platform/PersistedStorage.h>
#include <thread>
#include <atomic>

using namespace chip;
using namespace chip::DeviceLayer;

class MatterController
{
public:
    MatterController();
    ~MatterController();

    // Initialize controller (CHIP stack, storage, BLE, Thread)
    CHIP_ERROR Init();

    // Run controller main loop (blocks until shutdown)
    CHIP_ERROR Run();

    // Shutdown controller gracefully
    void Shutdown();

    // Open commissioning window (for multi-admin)
    CHIP_ERROR OpenCommissioningWindow(uint16_t timeoutSeconds = 300, uint16_t discriminator = 3840, uint32_t passcode = 12345678);

    // Close commissioning window
    CHIP_ERROR CloseCommissioningWindow();

private:
    // Initialize CHIP stack (storage is initialized automatically by Platform Manager)
    CHIP_ERROR InitChipStack();

    // Initialize BLE
    CHIP_ERROR InitBLE();

    // Initialize Thread/OTBR
    CHIP_ERROR InitThread();

    // Open commissioning window at startup
    CHIP_ERROR OpenStartupCommissioningWindow();

    // Main event loop (runs in separate thread)
    void EventLoop();

    // Controller state
    std::atomic<bool> mRunning;
    std::atomic<bool> mInitialized;
    std::atomic<bool> mChipStackInitialized;  // Track if CHIP stack was successfully initialized
    std::thread mEventLoopThread;

    // Commissioning window state
    std::atomic<bool> mCommissioningWindowOpen;
    uint16_t mCommissioningWindowTimeout;
    uint16_t mCommissioningWindowDiscriminator;
    uint32_t mCommissioningWindowPasscode;

    // Storage paths
    static constexpr const char * kStoragePath = "/var/lib/matter-controller";
    static constexpr const char * kKvsPath     = "/var/lib/matter-controller/chip_kvs";
    static constexpr const char * kFactoryPath = "/var/lib/matter-controller/chip_factory.ini";
    static constexpr const char * kConfigPath  = "/var/lib/matter-controller/chip_config.ini";
};

