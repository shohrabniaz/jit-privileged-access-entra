# Remove privileged membership when the JIT window has ended.
param()
. "$PSScriptRoot\00_Config.ps1"
Assert-LabTenant

$privId = Get-GroupIdByName $Global:JitLab.PrivilegedGroup
$now = (Get-Date).ToUniversalTime()
$state = @(Read-JitState)
$revoked = @()

foreach ($grant in $state) {
    if ($grant.Status -ne "active") { continue }
    $expires = [datetime]::Parse($grant.ExpiresUtc).ToUniversalTime()
    if ($now -lt $expires) { continue }
    try {
        Remove-MgGroupMemberByRef -GroupId $privId -DirectoryObjectId $grant.UserId -ErrorAction Stop
    } catch {
        Write-Host "Remove skipped for $($grant.User): $($_.Exception.Message)"
    }
    $grant.Status = "revoked"
    $grant | Add-Member -NotePropertyName RevokedUtc -NotePropertyValue $now.ToString("o") -Force
    $revoked += $grant
}

Save-JitState -Grants $state
if ($revoked.Count -eq 0) {
    Write-Host "No expired JIT grants."
} else {
    Write-Evidence -Name "JitRevoke" -Data $revoked | Out-Null
    $revoked | Format-Table GrantId, User, ExpiresUtc, Status -AutoSize
}
