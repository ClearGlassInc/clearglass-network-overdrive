Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Write-ClearGlassEvent {
 param([string]$Level,[string]$Event,[hashtable]$Data,[string]$LogPath)
 $record=[ordered]@{timestamp=[DateTimeOffset]::UtcNow.ToString('o');level=$Level;event=$Event;brand='ClearGlassInc';founder='Desmond Otieno Odhiambo';correlationId=$script:CorrelationId;data=$Data}
 $json=$record|ConvertTo-Json -Depth 8 -Compress
 if($LogPath){$directory=Split-Path -Parent $LogPath;if($directory-and-not(Test-Path -LiteralPath $directory)){New-Item -ItemType Directory -Path $directory -Force|Out-Null};Add-Content -LiteralPath $LogPath -Value $json -Encoding utf8}
 Write-Verbose $json
}
function Get-ClearGlassNetworkSnapshot {
 [CmdletBinding()]param()
 $adapters=@(Get-NetAdapter -ErrorAction Stop|ForEach-Object{[ordered]@{name=$_.Name;description=$_.InterfaceDescription;status=[string]$_.Status;linkSpeed=[string]$_.LinkSpeed;macAddress=[string]$_.MacAddress}})
 [ordered]@{capturedAt=[DateTimeOffset]::UtcNow.ToString('o');computerName=$env:COMPUTERNAME;adapters=$adapters;tcpGlobal=(netsh int tcp show global 2>&1|Out-String).Trim()}
}
function Test-ClearGlassPreflight {
 [CmdletBinding()]param([switch]$RequireAdministrator)
 $windows=$env:OS-eq'Windows_NT';$admin=$false
 if($windows){$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$admin=$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
 if(-not$windows){throw'Windows is required.'};if($RequireAdministrator-and-not$admin){throw'Administrator privileges are required for Apply or Rollback.'}
 if(-not(Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)-or-not(Get-Command netsh.exe -ErrorAction SilentlyContinue)){throw'Required Windows networking commands are unavailable.'}
 [pscustomobject]@{windows=$windows;administrator=$admin;ready=$true}
}
function New-ClearGlassPlan {
 [CmdletBinding()]param([ValidateSet('Balanced','Latency')][string]$Profile='Balanced')
 [ordered]@{schemaVersion=1;profile=$Profile;generatedAt=[DateTimeOffset]::UtcNow.ToString('o');commands=@([ordered]@{id='rss';arguments=@('int','tcp','set','global','rss=enabled');risk='low'},[ordered]@{id='autotuning';arguments=@('int','tcp','set','global','autotuninglevel=normal');risk='low'});exclusions=@('Forced duplex','Jumbo frames','Experimental autotuning','Registry Nagle edits','Firewall changes')}
}
function Invoke-ClearGlassNetsh {
 param([Parameter(Mandatory)][string[]]$Arguments)
 $allowed=@('int tcp set global rss=enabled','int tcp set global autotuninglevel=normal')
 if(($Arguments-join' ')-notin$allowed){throw'Command denied by allowlist.'}
 $output=& netsh.exe @Arguments 2>&1;if($LASTEXITCODE-ne0){throw"netsh failed: $($output-join' ')"}
}
function Invoke-ClearGlassNetworkOverdrive {
 [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
 param([ValidateSet('Audit','Plan','Apply','Rollback')][string]$Mode='Audit',[ValidateSet('Balanced','Latency')][string]$Profile='Balanced',[string]$StatePath=(Join-Path $env:ProgramData 'ClearGlassInc\NetworkOverdrive\state.json'),[string]$LogPath=(Join-Path $env:ProgramData 'ClearGlassInc\NetworkOverdrive\events.jsonl'))
 $script:CorrelationId=[guid]::NewGuid().ToString();Test-ClearGlassPreflight -RequireAdministrator:($Mode-in@('Apply','Rollback'))|Out-Null
 if($Mode-eq'Audit'){$snapshot=Get-ClearGlassNetworkSnapshot;Write-ClearGlassEvent -Level Information -Event 'audit.completed' -Data $snapshot -LogPath $LogPath;return[pscustomobject]$snapshot}
 if($Mode-eq'Plan'){return[pscustomobject](New-ClearGlassPlan -Profile $Profile)}
 if($Mode-eq'Rollback'){if(-not(Test-Path -LiteralPath $StatePath)){throw"Rollback state not found: $StatePath"};if($PSCmdlet.ShouldProcess('Windows TCP configuration','Restore safe Windows defaults')){Invoke-ClearGlassNetsh @('int','tcp','set','global','rss=enabled');Invoke-ClearGlassNetsh @('int','tcp','set','global','autotuninglevel=normal');Write-ClearGlassEvent -Level Information -Event 'rollback.completed' -Data @{statePath=$StatePath} -LogPath $LogPath};return}
 $stateDirectory=Split-Path -Parent $StatePath;if(-not(Test-Path -LiteralPath $stateDirectory)){New-Item -ItemType Directory -Path $stateDirectory -Force|Out-Null}
 [ordered]@{schemaVersion=1;createdAt=[DateTimeOffset]::UtcNow.ToString('o');before=Get-ClearGlassNetworkSnapshot}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $StatePath -Encoding utf8
 foreach($command in(New-ClearGlassPlan -Profile $Profile).commands){if($PSCmdlet.ShouldProcess($command.id,('netsh '+($command.arguments-join' ')))){Invoke-ClearGlassNetsh $command.arguments;Write-ClearGlassEvent -Level Information -Event 'change.applied' -Data @{id=$command.id;risk=$command.risk} -LogPath $LogPath}}
 Get-ClearGlassNetworkSnapshot
}
Export-ModuleMember -Function Get-ClearGlassNetworkSnapshot,Test-ClearGlassPreflight,New-ClearGlassPlan,Invoke-ClearGlassNetworkOverdrive
