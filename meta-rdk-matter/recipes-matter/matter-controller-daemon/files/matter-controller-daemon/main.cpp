/*
 * Copyright (c) 2025
 * SPDX-License-Identifier: Apache-2.0
 *
 * Matter Controller Daemon - Main Entry Point
 * Persistent Matter Controller with BLE Commissioning and Multi-Admin Support
 */

#include "MatterController.h"
#include <lib/support/CHIPMem.h>
#include <lib/support/CHIPPlatformMemory.h>
#include <platform/CHIPDeviceLayer.h>
#include <signal.h>
#include <unistd.h>

using namespace chip;
using namespace chip::DeviceLayer;

// Global controller instance for signal handling
MatterController * gController = nullptr;

// Signal handler for graceful shutdown
void SignalHandler(int signum)
{
    ChipLogProgress(NotSpecified, "Received signal %d, shutting down...", signum);
    if (gController != nullptr)
    {
        gController->Shutdown();
    }
    exit(0);
}

int main(int argc, char * argv[])
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    // Initialize platform memory
    Platform::MemoryInit();

    // Register signal handlers
    signal(SIGINT, SignalHandler);
    signal(SIGTERM, SignalHandler);

    ChipLogProgress(NotSpecified, "Matter Controller Daemon starting...");

    // Create controller instance
    gController = new MatterController();
    if (gController == nullptr)
    {
        ChipLogError(NotSpecified, "Failed to allocate MatterController");
        return -1;
    }

    // Initialize controller
    err = gController->Init();
    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(NotSpecified, "Controller initialization failed: %" CHIP_ERROR_FORMAT, err.Format());
        delete gController;
        Platform::MemoryShutdown();
        return -1;
    }

    ChipLogProgress(NotSpecified, "Matter Controller Daemon initialized successfully");

    // Run controller main loop (blocks until shutdown)
    err = gController->Run();
    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(NotSpecified, "Controller run failed: %" CHIP_ERROR_FORMAT, err.Format());
    }

    // Cleanup
    gController->Shutdown();
    delete gController;
    Platform::MemoryShutdown();

    ChipLogProgress(NotSpecified, "Matter Controller Daemon stopped");
    return (err == CHIP_NO_ERROR) ? 0 : -1;
}

