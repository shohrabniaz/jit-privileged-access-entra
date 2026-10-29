# Laboratory tenant for the JIT privileged-access pilot.
# No passwords are stored here. Same free directory as the JML lab.
$Global:JitLab = @{
    TenantId        = "a76a68a8-6243-4b0e-b11c-98e815e91820"
    Domain          = "niazkhanghostgmail.onmicrosoft.com"
    EvidencePath    = (Join-Path $PSScriptRoot "evidence")
    StateFile       = (Join-Path $PSScriptRoot "evidence\jit_active.json")
    PrivilegedGroup = "SG-CMIT-Privileged-Admins"
    EligibleGroup   = "SG-CMIT-Engineers"
    DefaultMinutes  = 60
    MaxMinutes      = 120
}

New-Item -ItemType Directory -Force -Path $Global:JitLab.EvidencePath | Out-Null
if (-not (Test-Path $Global:JitLab.StateFile)) {
    "[]" | Set-Content -Path $Global:JitLab.StateFile -Encoding UTF8
}

function Assert-LabTenant {
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Not connected. Run Connect-MgGraph -TenantId $($Global:JitLab.TenantId) -Scopes Group.ReadWrite.All,User.Read.All,Directory.Read.All" }
    if ($ctx.TenantId -ne $Global:JitLab.TenantId) {
        throw "Connected tenant $($ctx.TenantId) is not the lab tenant. Aborting."
    }
}

function Write-Evidence {
    param([string]$Name, [object]$Data)
    $file = Join-Path $Global:JitLab.EvidencePath ("{0}_{1}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"), $Name)
    $Data | ConvertTo-Json -Depth 6 | Set-Content -Path $file -Encoding UTF8
    Write-Host "Evidence written: $file"
    return $file
}

function Get-GroupIdByName {
    param([string]$DisplayName)
    $g = Get-MgGroup -Filter "displayName eq '$DisplayName'"
    if (-not $g) { throw "Group not found: $DisplayName" }
    return $g.Id
}

function Read-JitState {
    $raw = Get-Content -Path $Global:JitLab.StateFile -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return @() }
    $data = $raw | ConvertFrom-Json
    if ($null -eq $data) { return @() }
    return @($data)
}

function Save-JitState {
    param([object[]]$Grants)
    $Grants | ConvertTo-Json -Depth 6 | Set-Content -Path $Global:JitLab.StateFile -Encoding UTF8
}
