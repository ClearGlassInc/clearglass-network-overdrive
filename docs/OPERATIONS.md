# Operations

Import the module:

    Import-Module ./src/ClearGlass.NetworkOverdrive.psd1 -Force

Safe sequence:

    Invoke-ClearGlassNetworkOverdrive -Mode Audit
    Invoke-ClearGlassNetworkOverdrive -Mode Plan
    Invoke-ClearGlassNetworkOverdrive -Mode Apply -WhatIf
    Invoke-ClearGlassNetworkOverdrive -Mode Apply -Confirm

A negotiated 100 Mbps link cannot become 1 Gbps through TCP tuning. Inspect the cable, switch or router port, USB adapter, and auto-negotiation first.

Rollback:

    Invoke-ClearGlassNetworkOverdrive -Mode Rollback -WhatIf
    Invoke-ClearGlassNetworkOverdrive -Mode Rollback -Confirm

State and events default to ProgramData under ClearGlassInc NetworkOverdrive. Preserve them for incident review. If preflight fails, make no changes. If Apply fails or performance regresses, capture an Audit, roll back, and compare evidence. Never stack changes onto an unexplained regression.
