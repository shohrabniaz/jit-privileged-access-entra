$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$log = Join-Path $PSScriptRoot "evidence\lab_run.log"
function Log([string]$m) {
    $line = "{0} {1}" -f (Get-Date -Format "HH:mm:ss"), $m
    Add-Content -Path $log -Value $line
    Write-Host $line
}
"" | Set-Content -Path $log -Encoding UTF8
Log "START"

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

$tenant = "a76a68a8-6243-4b0e-b11c-98e815e91820"
Log "Opening device-code login for tenant $tenant"
Log "Open https://login.microsoft.com/device and enter the code shown below"

try {
    Connect-MgGraph -TenantId $tenant -Scopes "Group.ReadWrite.All","User.Read.All","Directory.Read.All" -UseDeviceCode -NoWelcome 2>&1 | ForEach-Object {
        Log ($_ | Out-String).Trim()
    }
} catch {
    Log ("CONNECT_FAIL " + $_.Exception.Message)
    throw
}

$c = Get-MgContext
if (-not $c) { Log "NO_CONTEXT"; throw "Not connected" }
if ($c.TenantId -ne $tenant) { Log ("WRONG_TENANT " + $c.TenantId); throw "Wrong tenant" }
Log ("CONNECTED " + $c.Account)

Log "01 inventory"
& .\01_Inventory_Standing_Privilege.ps1 *>&1 | ForEach-Object { Log ($_ | Out-String).Trim() }

Log "02 grant"
& .\02_Grant_JIT_Elevation.ps1 `
    -UserPrincipalName "mover.test01@niazkhanghostgmail.onmicrosoft.com" `
    -Minutes 15 `
    -Reason "Lab pilot of time-boxed admin" `
    -Approver "Lab supervisor" *>&1 | ForEach-Object { Log ($_ | Out-String).Trim() }

Log "wait 70s"
Start-Sleep -Seconds 70
$statePath = Join-Path $PSScriptRoot "evidence\jit_active.json"
$state = @(Get-Content $statePath -Raw | ConvertFrom-Json)
foreach ($g in $state) {
    if ($g.Status -eq "active") {
        $g.ExpiresUtc = (Get-Date).ToUniversalTime().AddMinutes(-1).ToString("o")
    }
}
$state | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding UTF8

Log "03 revoke"
& .\03_Revoke_Expired_JIT.ps1 *>&1 | ForEach-Object { Log ($_ | Out-String).Trim() }

Log "04 exposure"
& .\04_Measure_Exposure.ps1 *>&1 | ForEach-Object { Log ($_ | Out-String).Trim() }

Log "DONE"
