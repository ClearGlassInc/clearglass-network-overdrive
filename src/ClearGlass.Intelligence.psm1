# ClearGlassInc Network Intelligence
# Founder and principal author: Desmond Otieno Odhiambo
# Security boundary: recommendations are data only and never execute commands.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ClearGlassHealthScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(0,100)][double]$PacketLossPercent,
        [Parameter(Mandatory)][ValidateRange(0,10000)][double]$LatencyMs,
        [Parameter(Mandatory)][ValidateRange(0,10000)][double]$JitterMs,
        [Parameter(Mandatory)][ValidateRange(0,[long]::MaxValue)][long]$AdapterErrors
    )
    $score = 100.0
    $score -= [Math]::Min(50.0, $PacketLossPercent * 10.0)
    $score -= [Math]::Min(25.0, $LatencyMs / 8.0)
    $score -= [Math]::Min(15.0, $JitterMs / 4.0)
    if ($AdapterErrors -gt 0) { $score -= [Math]::Min(10.0, [Math]::Log10($AdapterErrors + 1) * 5.0) }
    [Math]::Round([Math]::Max(0.0, $score), 2)
}

function New-ClearGlassRecommendation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][hashtable]$Evidence,
        [ValidateSet('Disabled','Advisory')][string]$IntelligenceMode = 'Disabled'
    )
    $required = @('packetLossPercent','latencyMs','jitterMs','adapterErrors','linkSpeedMbps')
    foreach ($field in $required) {
        if (-not $Evidence.ContainsKey($field)) { throw "Evidence field is required: $field" }
    }
    $score = Get-ClearGlassHealthScore -PacketLossPercent $Evidence.packetLossPercent -LatencyMs $Evidence.latencyMs -JitterMs $Evidence.jitterMs -AdapterErrors $Evidence.adapterErrors
    $actions = [System.Collections.Generic.List[object]]::new()
    if ($Evidence.linkSpeedMbps -le 100) {
        $actions.Add([ordered]@{ id='inspect-physical-link'; priority=1; executable=$false; reason='Negotiated link is 100 Mbps or lower.' })
    }
    if ($Evidence.packetLossPercent -gt 1) {
        $actions.Add([ordered]@{ id='investigate-packet-loss'; priority=2; executable=$false; reason='Packet loss exceeds the 1 percent guardrail.' })
    }
    if ($Evidence.adapterErrors -gt 0) {
        $actions.Add([ordered]@{ id='inspect-adapter-errors'; priority=3; executable=$false; reason='Adapter errors were observed.' })
    }
    [pscustomobject][ordered]@{
        schemaVersion = 1
        decisionId = [guid]::NewGuid().ToString()
        generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        owner = 'ClearGlassInc'
        founder = 'Desmond Otieno Odhiambo'
        mode = $IntelligenceMode
        healthScore = $score
        executionAuthorized = $false
        evidence = $Evidence
        recommendations = @($actions)
        provenance = [ordered]@{ engine='deterministic-policy'; version='1.0.0'; externalModel=$null }
    }
}

function Test-ClearGlassCircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(0,100)][double]$BaselineScore,
        [Parameter(Mandatory)][ValidateRange(0,100)][double]$CurrentScore,
        [ValidateRange(0,100)][double]$MaximumRegression = 5
    )
    $regression = [Math]::Round($BaselineScore - $CurrentScore, 2)
    [pscustomobject][ordered]@{
        shouldRollback = $regression -gt $MaximumRegression
        regression = $regression
        threshold = $MaximumRegression
        state = if ($regression -gt $MaximumRegression) { 'Open' } else { 'Closed' }
    }
}

Export-ModuleMember -Function Get-ClearGlassHealthScore,New-ClearGlassRecommendation,Test-ClearGlassCircuitBreaker
