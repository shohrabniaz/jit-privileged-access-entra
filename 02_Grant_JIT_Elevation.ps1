# Time-box one engineer into the privileged group.
# This is the free-tier substitute for Entra PIM. It does not buy a licence.
param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [int]$Minutes = 60,
    [Parameter(Mandatory=$true)][string]$Reason,
    [Parameter(Mandatory=$true)][string]$Approver
)
. "$PSScriptRoot\00_Config.ps1"
Assert-LabTenant

if ($Minutes -lt 15 -or $Minutes -gt $Global:JitLab.MaxMinutes) {
    throw "Minutes must be between 15 and $($Global:JitLab.MaxMinutes)."
}
if ([string]::IsNullOrWhiteSpace($Reason) -or [string]::IsNullOrWhiteSpace($Approver)) {
    throw "A reason and an approver name are required."
}

$user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -Property Id,DisplayName,UserPrincipalName,AccountEnabled
if (-not $user) { throw "User not found: $UserPrincipalName" }
if (-not $user.AccountEnabled) { throw "Refusing elevation. The account is disabled." }

$eligibleId = Get-GroupIdByName $Global:JitLab.EligibleGroup
$eligible = @(Get-MgGroupMember -GroupId $eligibleId -All)
if (@($eligible | Where-Object { $_.Id -eq $user.Id }).Count -eq 0) {
    throw "Refusing elevation. $UserPrincipalName is not in $($Global:JitLab.EligibleGroup)."
}

$privId = Get-GroupIdByName $Global:JitLab.PrivilegedGroup
$privMembers = @(Get-MgGroupMember -GroupId $privId -All)
if (@($privMembers | Where-Object { $_.Id -eq $user.Id }).Count -gt 0) {
    throw "Refusing elevation. $UserPrincipalName already has standing privileged membership. Remove that first."
}

$open = @(Read-JitState | Where-Object { $_.UserId -eq $user.Id -and $_.Status -eq "active" })
if ($open.Count -gt 0) { throw "An active JIT grant already exists for this user." }

New-MgGroupMember -GroupId $privId -DirectoryObjectId $user.Id | Out-Null

$now = (Get-Date).ToUniversalTime()
$grant = [pscustomobject]@{
    GrantId    = "JIT-" + (Get-Date -Format "yyyyMMddHHmmss")
    User       = $user.UserPrincipalName
    UserId     = $user.Id
    Group      = $Global:JitLab.PrivilegedGroup
    Minutes    = $Minutes
    Reason     = $Reason
    Approver   = $Approver
    GrantedUtc = $now.ToString("o")
    ExpiresUtc = $now.AddMinutes($Minutes).ToString("o")
    Status     = "active"
}

$state = @(Read-JitState) + @($grant)
Save-JitState -Grants $state
Write-Evidence -Name "JitGrant_$($user.UserPrincipalName.Split('@')[0])" -Data $grant | Out-Null
$grant | Format-List
