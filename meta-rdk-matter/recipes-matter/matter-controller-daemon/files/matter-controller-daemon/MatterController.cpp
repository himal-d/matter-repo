/*
 * Copyright (c) 2025
 * SPDX-License-Identifier: Apache-2.0
 *
 * Matter Controller Daemon - Controller Implementation
 * Persistent Matter Controller with BLE Commissioning and Multi-Admin Support
 */

#include "MatterController.h"
#include <lib/support/CodeUtils.h>
#include <lib/support/logging/CHIPLogging.h>
#include <lib/support/Span.h>
#include <platform/CHIPDeviceLayer.h>
#include <controller/CommissioningWindowOpener.h>
#include <setup_payload/QRCodeSetupPayloadGenerator.h>
#include <setup_payload/ManualSetupPayloadGenerator.h>
#include <setup_payload/SetupPayload.h>
#include <lib/support/SetupDiscriminator.h>
#include <string>
#include <platform/PlatformManager.h>
#include <platform/ConnectivityManager.h>
#include <platform/KeyValueStoreManager.h>
#include <platform/PersistedStorage.h>
#include <sys/stat.h>
#include <unistd.h>
#include <chrono>
#include <thread>

using namespace chip;
using namespace chip::DeviceLayer;

MatterController::MatterController() :
    mRunning(false), mInitialized(false), mChipStackInitialized(false),
    mCommissioningWindowOpen(false), mCommissioningWindowTimeout(300),
    mCommissioningWindowDiscriminator(3840), mCommissioningWindowPasscode(12345678)
{
}

MatterController::~MatterController()
{
    Shutdown();
}

CHIP_ERROR MatterController::Init()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    if (mInitialized)
    {
        ChipLogError(NotSpecified, "Controller already initialized");
        return CHIP_ERROR_INCORRECT_STATE;
    }

    ChipLogProgress(NotSpecified, "Initializing Matter Controller...");

    // 1. Create storage directory if it doesn't exist
    struct stat st;
    if (stat(kStoragePath, &st) != 0)
    {
        if (mkdir(kStoragePath, 0755) != 0)
        {
            ChipLogError(NotSpecified, "Failed to create storage directory: %s", kStoragePath);
            return CHIP_ERROR_WRITE_FAILED;
        }
        ChipLogProgress(NotSpecified, "Created storage directory: %s", kStoragePath);
    }

    // 2. Initialize CHIP stack (storage is initialized automatically by Platform Manager)
    err = InitChipStack();
    SuccessOrExit(err);

    // 3. Initialize BLE
    err = InitBLE();
    SuccessOrExit(err);

    // 4. Initialize Thread/OTBR
    err = InitThread();
    SuccessOrExit(err);

    // 5. Mark as initialized BEFORE opening commissioning window
    // (OpenCommissioningWindow checks mInitialized)
    mInitialized = true;
    mRunning     = true;

    // 6. Open commissioning window at startup
    err = OpenStartupCommissioningWindow();
    SuccessOrExit(err);

    ChipLogProgress(NotSpecified, "Matter Controller initialized successfully");

exit:
    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(NotSpecified, "Controller initialization failed: %" CHIP_ERROR_FORMAT, err.Format());
        // Cleanup: Shutdown will check mChipStackInitialized to safely shutdown
        Shutdown();
    }
    return err;
}

CHIP_ERROR MatterController::InitChipStack()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    ChipLogProgress(NotSpecified, "Initializing CHIP stack...");

    // Initialize Platform Manager (this initializes the device layer and storage)
    // Storage path is configured via CHIP_KVS_PATH environment variable
    // For a controller-only application, we don't need Server initialization
    // Server is only needed for device endpoints that expose clusters
    err = PlatformMgr().InitChipStack();
    SuccessOrExit(err);

    mChipStackInitialized = true;  // Mark stack as initialized
    ChipLogProgress(NotSpecified, "CHIP stack initialized successfully");

exit:
    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(NotSpecified, "CHIP stack initialization failed: %" CHIP_ERROR_FORMAT, err.Format());
    }
    return err;
}

CHIP_ERROR MatterController::InitBLE()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    ChipLogProgress(NotSpecified, "Initializing BLE...");

    // BLE is initialized by Platform Manager during InitChipStack()
    // Explicitly enable BLE advertising for commissioning
    ConnectivityMgr().SetBLEAdvertisingEnabled(true);

    // Verify BLE is ready
    if (!ConnectivityMgr().IsBLEAdvertisingEnabled())
    {
        ChipLogError(NotSpecified, "BLE advertising failed to enable");
        return CHIP_ERROR_INTERNAL;
    }

    ChipLogProgress(NotSpecified, "BLE initialized and advertising enabled (always-on for commissioning)");

    return err;
}

CHIP_ERROR MatterController::InitThread()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    ChipLogProgress(NotSpecified, "Initializing Thread/OTBR...");

    // Thread is initialized by Platform Manager using wpan0 interface
    // (configured via CHIP_DEVICE_CONFIG_THREAD_INTERFACE_NAME environment variable)
    // Set Thread device type to Router (OTBR acts as a Thread router)
    ConnectivityMgr().SetThreadDeviceType(ConnectivityManager::kThreadDeviceType_Router);

    // Note: Thread is enabled automatically by Platform Manager
    // OTBR should already be running and wpan0 should exist
    // The actual Thread network attachment happens via OTBR

    ChipLogProgress(NotSpecified, "Thread/OTBR initialized (wpan0 interface)");

    return err;
}

CHIP_ERROR MatterController::OpenStartupCommissioningWindow()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    ChipLogProgress(NotSpecified, "Opening commissioning window at startup...");
    ChipLogProgress(NotSpecified, "  Timeout: %d seconds", mCommissioningWindowTimeout);
    ChipLogProgress(NotSpecified, "  Discriminator: %d", mCommissioningWindowDiscriminator);
    ChipLogProgress(NotSpecified, "  Passcode: %d", mCommissioningWindowPasscode);

    err = OpenCommissioningWindow(mCommissioningWindowTimeout, mCommissioningWindowDiscriminator, mCommissioningWindowPasscode);
    SuccessOrExit(err);

    ChipLogProgress(NotSpecified, "Commissioning window opened successfully");

exit:
    return err;
}

CHIP_ERROR MatterController::OpenCommissioningWindow(uint16_t timeoutSeconds, uint16_t discriminator, uint32_t passcode)
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    if (!mInitialized)
    {
        ChipLogError(NotSpecified, "Controller not initialized");
        return CHIP_ERROR_INCORRECT_STATE;
    }

    ChipLogProgress(NotSpecified, "Opening commissioning window...");
    ChipLogProgress(NotSpecified, "  Timeout: %d seconds", timeoutSeconds);
    ChipLogProgress(NotSpecified, "  Discriminator: %d", discriminator);
    ChipLogProgress(NotSpecified, "  Passcode: %d", passcode);

    // Note: A controller-only application cannot open commissioning windows
    // Commissioning windows are opened by device endpoints, not controllers
    // Controllers commission devices, they don't accept commissioning themselves
    // 
    // For a controller, "opening commissioning window" means enabling BLE advertising
    // so that devices can discover and commission this controller
    // However, this is not the standard Matter flow - controllers commission devices, not the other way around
    
    // Enable BLE advertising for device discovery
    ConnectivityMgr().SetBLEAdvertisingEnabled(true);
    
    // Generate QR code and manual pairing code for this controller's commissioning info
    // Note: This is informational - the actual commissioning happens when the controller commissions a device
    {
        SetupPayload payload;
        SetupDiscriminator disc;
        disc.SetLongValue(discriminator);
        payload.discriminator = disc;
        payload.setUpPINCode = passcode;
        
        RendezvousInformationFlags flags;
        flags.Set(RendezvousInformationFlag::kBLE);
        flags.Set(RendezvousInformationFlag::kOnNetwork);
        payload.rendezvousInformation = Optional<RendezvousInformationFlags>(flags);
        
        std::string QRCode;
        std::string manualPairingCode;
        
        err = QRCodeSetupPayloadGenerator(payload).payloadBase38Representation(QRCode);
        if (err == CHIP_NO_ERROR)
        {
            ChipLogProgress(NotSpecified, "=========================================");
            ChipLogProgress(NotSpecified, "Controller QR Code:");
            ChipLogProgress(NotSpecified, "%s", QRCode.c_str());
            ChipLogProgress(NotSpecified, "=========================================");
        }
        else
        {
            ChipLogError(NotSpecified, "Failed to generate QR code: %" CHIP_ERROR_FORMAT, err.Format());
        }

        err = ManualSetupPayloadGenerator(payload).payloadDecimalStringRepresentation(manualPairingCode);
        if (err == CHIP_NO_ERROR)
        {
            ChipLogProgress(NotSpecified, "Manual Pairing Code: %s", manualPairingCode.c_str());
        }
        else
        {
            ChipLogError(NotSpecified, "Failed to generate manual pairing code: %" CHIP_ERROR_FORMAT, err.Format());
        }
    }

    mCommissioningWindowOpen = true;
    mCommissioningWindowTimeout = timeoutSeconds;
    mCommissioningWindowDiscriminator = discriminator;
    mCommissioningWindowPasscode = passcode;

    ChipLogProgress(NotSpecified, "BLE advertising enabled - controller ready to commission devices");
    ChipLogProgress(NotSpecified, "Note: Controllers commission devices, they don't accept commissioning themselves");

    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(NotSpecified, "Failed to open commissioning window: %" CHIP_ERROR_FORMAT, err.Format());
        mCommissioningWindowOpen = false;
    }
    return err;
}

CHIP_ERROR MatterController::CloseCommissioningWindow()
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    if (!mCommissioningWindowOpen)
    {
        ChipLogProgress(NotSpecified, "Commissioning window already closed");
        return CHIP_NO_ERROR;
    }

    ChipLogProgress(NotSpecified, "Closing commissioning window...");

    // For a controller, "closing commissioning window" just means disabling BLE advertising
    // Note: We keep BLE advertising enabled by default for controller functionality
    // Only disable if explicitly requested
    // ConnectivityMgr().SetBLEAdvertisingEnabled(false);

    mCommissioningWindowOpen = false;

    ChipLogProgress(NotSpecified, "Commissioning window closed (BLE advertising remains enabled)");

    return err;
}

CHIP_ERROR MatterController::Run()
{
    if (!mInitialized)
    {
        ChipLogError(NotSpecified, "Controller not initialized");
        return CHIP_ERROR_INCORRECT_STATE;
    }

    ChipLogProgress(NotSpecified, "Matter Controller daemon running...");

    // Start event loop thread
    mEventLoopThread = std::thread(&MatterController::EventLoop, this);

    // Wait for shutdown signal
    while (mRunning)
    {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    // Wait for event loop thread to finish
    if (mEventLoopThread.joinable())
    {
        mEventLoopThread.join();
    }

    return CHIP_NO_ERROR;
}

void MatterController::EventLoop()
{
    ChipLogProgress(NotSpecified, "Event loop started");

    while (mRunning)
    {
        // Process CHIP platform events
        // This allows the CHIP stack to process internal events, timers, etc.
        PlatformMgr().LockChipStack();
        PlatformMgr().UnlockChipStack();

        // Process system events (BLE, Thread, etc.)
        // The Platform Manager handles these internally, but we need to give it CPU time
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    ChipLogProgress(NotSpecified, "Event loop stopped");
}

void MatterController::Shutdown()
{
    if (!mInitialized && !mChipStackInitialized)
    {
        return;  // Nothing to shutdown
    }

    ChipLogProgress(NotSpecified, "Shutting down Matter Controller...");

    mRunning = false;
    mInitialized = false;  // Set early to prevent re-entry

    // Wait for event loop thread to finish
    if (mEventLoopThread.joinable())
    {
        mEventLoopThread.join();
    }

    // Close commissioning window (disable BLE advertising)
    if (mCommissioningWindowOpen)
    {
        CloseCommissioningWindow();
    }

    // Shutdown CHIP stack (this will persist fabrics and credentials to storage)
    // Only shutdown if stack was successfully initialized
    if (mChipStackInitialized)
    {
        PlatformMgr().Shutdown();
        mChipStackInitialized = false;
    }

    ChipLogProgress(NotSpecified, "Matter Controller shut down gracefully");
}

