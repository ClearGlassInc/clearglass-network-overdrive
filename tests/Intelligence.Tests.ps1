BeforeAll {
    Import-Module "$PSScriptRoot/../src/ClearGlass.Intelligence.psm1" -Force
}
Describe 'ClearGlass guarded intelligence' {
    It 'embeds founder provenance and denies execution' {
        $evidence = @{ packetLossPercent=0; latencyMs=10; jitterMs=2; adapterErrors=0; linkSpeedMbps=1000 }
        $result = New-ClearGlassRecommendation -Evidence $evidence -IntelligenceMode Advisory
        $result.founder | Should -Be 'Desmond Otieno Odhiambo'
        $result.executionAuthorized | Should -BeFalse
        $result.provenance.engine | Should -Be 'deterministic-policy'
    }
    It 'detects a physical link bottleneck' {
        $evidence = @{ packetLossPercent=0; latencyMs=10; jitterMs=2; adapterErrors=0; linkSpeedMbps=100 }
        $result = New-ClearGlassRecommendation -Evidence $evidence -IntelligenceMode Advisory
        $result.recommendations.id | Should -Contain 'inspect-physical-link'
    }
    It 'opens the circuit breaker on excessive regression' {
        $breaker = Test-ClearGlassCircuitBreaker -BaselineScore 90 -CurrentScore 80 -MaximumRegression 5
        $breaker.shouldRollback | Should -BeTrue
        $breaker.state | Should -Be 'Open'
    }
    It 'fails closed on incomplete evidence' {
        { New-ClearGlassRecommendation -Evidence @{ latencyMs=10 } -IntelligenceMode Advisory } | Should -Throw
    }
}
