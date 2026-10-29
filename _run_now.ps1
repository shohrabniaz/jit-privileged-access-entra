$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

$tenant = "a76a68a8-6243-4b0e-b11c-98e815e91820"
$c = Get-MgContext
if (-not $c -or $c.TenantId -ne $tenant) {
    Write-Host "Connecting to lab tenant (browser)..."
    Connect-MgGraph -TenantId $tenant -Scopes "Group.ReadWrite.All","User.Read.All","Directory.Read.All" -ContextScope CurrentUser -NoWelcome
    $c = Get-MgContext
}
if (-not $c) { throw "Not connected." }
if ($c.TenantId -ne $tenant) { throw "Wrong tenant: $($c.TenantId)" }
Write-Host ("Connected as " + $c.Account + " tenant " + $c.TenantId)

Write-Host "=== 01 Inventory ==="
& .\01_Inventory_Standing_Privilege.ps1

Write-Host "=== 02 Grant JIT ==="
& .\02_Grant_JIT_Elevation.ps1 `
    -UserPrincipalName "mover.test01@niazkhanghostgmail.onmicrosoft.com" `
    -Minutes 15 `
    -Reason "Lab pilot of time-boxed admin" `
    -Approver "Lab supervisor"

Write-Host "Waiting 70 seconds, then marking grant expired for revoke proof..."
Start-Sleep -Seconds 70
$statePath = Join-Path $PSScriptRoot "evidence\jit_active.json"
$state = @(Get-Content $statePath -Raw | ConvertFrom-Json)
foreach ($g in $state) {
    if ($g.Status -eq "active") {
        $g.ExpiresUtc = (Get-Date).ToUniversalTime().AddMinutes(-1).ToString("o")
    }
}
$state | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding UTF8

Write-Host "=== 03 Revoke ==="
& .\03_Revoke_Expired_JIT.ps1

Write-Host "=== 04 Exposure ==="
& .\04_Measure_Exposure.ps1

Write-Host "DONE"
Get-ChildItem .\evidence\*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 8 Name, LastWriteTime
