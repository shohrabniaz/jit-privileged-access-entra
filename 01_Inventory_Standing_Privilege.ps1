# List who is in the privileged group right now.
# A member with no active JIT grant is standing privilege.
param()
. "$PSScriptRoot\00_Config.ps1"
Assert-LabTenant

$privId = Get-GroupIdByName $Global:JitLab.PrivilegedGroup
$members = @(Get-MgGroupMember -GroupId $privId -All)
$active = @(Read-JitState | Where-Object { $_.Status -eq "active" })
$activeIds = @($active | ForEach-Object { $_.UserId })

$rows = @()
foreach ($m in $members) {
    $u = Get-MgUser -UserId $m.Id -Property Id,DisplayName,UserPrincipalName,AccountEnabled,Department,JobTitle -ErrorAction SilentlyContinue
    if (-not $u) { continue }
    $grant = $active | Where-Object { $_.UserId -eq $u.Id } | Select-Object -First 1
    $kind = "STANDING"
    if ($grant) { $kind = "JIT_ACTIVE" }
    if (-not $u.AccountEnabled) { $kind = "DISABLED_STILL_PRIVILEGED" }
    $rows += [pscustomobject]@{
        DisplayName    = $u.DisplayName
        UPN            = $u.UserPrincipalName
        AccountEnabled = $u.AccountEnabled
        Kind           = $kind
        ExpiresUtc     = $(if ($grant) { $grant.ExpiresUtc } else { $null })
    }
}

Write-Evidence -Name "StandingPrivilegeInventory" -Data $rows | Out-Null
$rows | Format-Table -AutoSize
Write-Host ("Standing or disabled privileged accounts: {0}" -f @($rows | Where-Object { $_.Kind -ne "JIT_ACTIVE" }).Count)
