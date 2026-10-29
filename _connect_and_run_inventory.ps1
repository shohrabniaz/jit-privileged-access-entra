$ErrorActionPreference = "Stop"
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

$tenant = "a76a68a8-6243-4b0e-b11c-98e815e91820"
Write-Host "Connecting to lab tenant $tenant with device code ..."
Write-Host "A code will appear. Open https://microsoft.com/devicelogin and complete sign-in."
Connect-MgGraph -TenantId $tenant -Scopes "Group.ReadWrite.All","User.Read.All","Directory.Read.All" -UseDeviceCode -NoWelcome
$c = Get-MgContext
if (-not $c -or $c.TenantId -ne $tenant) {
    throw "Connected tenant does not match the laboratory."
}
Write-Host ("Connected as " + $c.Account)
Set-Location $PSScriptRoot
Write-Host "=== 01 Inventory ==="
& .\01_Inventory_Standing_Privilege.ps1
