# Compare a week of standing admin access with the JIT windows that were actually granted.
# Standing hours are a model: one always-on admin for 7 days. They are not a stopwatch of a live team.
param(
    [int]$StandingAdmins = 1,
    [int]$Days = 7
)
. "$PSScriptRoot\00_Config.ps1"

$grants = @(Read-JitState)
$jitMinutes = 0
foreach ($g in $grants) {
    if ($g.Minutes) { $jitMinutes += [int]$g.Minutes }
}
$standingHours = $StandingAdmins * 24 * $Days
$jitHours = [math]::Round($jitMinutes / 60, 2)
$reduction = 0
if ($standingHours -gt 0) {
    $reduction = [math]::Round((1 - ($jitHours / $standingHours)) * 100, 1)
}

$result = [pscustomobject]@{
    StandingAdmins       = $StandingAdmins
    WindowDays           = $Days
    StandingHours        = $standingHours
    JitGrants            = $grants.Count
    JitHours             = $jitHours
    ExposureReductionPct = $reduction
    Note                 = "Standing hours assume the admin account stays privileged for the whole window. JIT hours are the sum of granted minutes."
}
Write-Evidence -Name "ExposureComparison" -Data $result | Out-Null
$result | Format-List
