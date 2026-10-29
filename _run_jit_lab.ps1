$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

$tenant = "a76a68a8-6243-4b0e-b11c-98e815e91820"
Write-Host "Connecting to lab tenant $tenant ..."
Write-Host "A browser window should open. Sign in as the lab admin."

# Browser auth in a real console window (avoids device-code listener issues)
Connect-MgGraph -TenantId $tenant -Scopes "Group.ReadWrite.All","User.Read.All","Directory.Read.All" -ContextScope CurrentUser -NoWelcome

$c = Get-MgContext
if (-not $c) { throw "Not connected." }
if ($c.TenantId -ne $tenant) { throw "Connected tenant $($c.TenantId) != lab $tenant" }
Write-Host ("Connected as " + $c.Account)

Write-Host ""
Write-Host "=== 01 Inventory ===" -ForegroundColor Cyan
& .\01_Inventory_Standing_Privilege.ps1

Write-Host ""
Write-Host "=== 02 Grant JIT (15 minutes window; wait 70s then revoke for the live proof) ===" -ForegroundColor Cyan
& .\02_Grant_JIT_Elevation.ps1 `
    -UserPrincipalName "mover.test01@niazkhanghostgmail.onmicrosoft.com" `
    -Minutes 15 `
    -Reason "Lab pilot of time-boxed admin" `
    -Approver "Lab supervisor"

Write-Host ""
Write-Host "Grant issued. For a quick live proof this run will force-revoke after 70 seconds" -ForegroundColor Yellow
Write-Host "by writing ExpiresUtc into the past, then calling revoke. Leave this window open."
Start-Sleep -Seconds 70
# Force the active grant to look expired so revoke can run without a 15-minute wait.
$statePath = Join-Path $PSScriptRoot "evidence\jit_active.json"
$state = @(Get-Content $statePath -Raw | ConvertFrom-Json)
foreach ($g in $state) {
    if ($g.Status -eq "active") {
        $g.ExpiresUtc = (Get-Date).ToUniversalTime().AddMinutes(-1).ToString("o")
    }
}
$state | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding UTF8

Write-Host ""
Write-Host "=== 03 Revoke expired ===" -ForegroundColor Cyan
& .\03_Revoke_Expired_JIT.ps1

Write-Host ""
Write-Host "=== 04 Exposure ===" -ForegroundColor Cyan
& .\04_Measure_Exposure.ps1

Write-Host ""
Write-Host "Lab complete. JSON evidence is under .\evidence\" -ForegroundColor Green
Write-Host "Press Enter to close."
Read-Host | Out-Null
