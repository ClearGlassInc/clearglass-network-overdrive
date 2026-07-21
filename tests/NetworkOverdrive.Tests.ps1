BeforeAll{Import-Module "$PSScriptRoot/../src/ClearGlass.NetworkOverdrive.psd1" -Force}
Describe 'ClearGlass policy' {
 It 'creates a versioned plan' {$plan=New-ClearGlassPlan;$plan.schemaVersion|Should -Be 1;$plan.commands.Count|Should -Be 2}
 It 'excludes unsafe tuning' {$plan=New-ClearGlassPlan;$plan.exclusions|Should -Contain 'Forced duplex';$plan.exclusions|Should -Contain 'Jumbo frames';$plan.exclusions|Should -Contain 'Experimental autotuning'}
 It 'supports WhatIf' {(Get-Command Invoke-ClearGlassNetworkOverdrive).Parameters.Keys|Should -Contain 'WhatIf'}
 It 'exports four functions' {(Get-Module ClearGlass.NetworkOverdrive).ExportedFunctions.Keys.Count|Should -Be 4}
}
