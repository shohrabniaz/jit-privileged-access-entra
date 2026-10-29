try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $c = Get-MgContext
    if ($c) {
        Write-Output ("TENANT=" + $c.TenantId)
        Write-Output ("ACCOUNT=" + $c.Account)
    } else {
        Write-Output "NO_CONTEXT"
    }
} catch {
    Write-Output ("ERR=" + $_.Exception.Message)
}
