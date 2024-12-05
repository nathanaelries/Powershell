function Get-UserManager {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    try {
        $user = Get-ADUser $UserName -Properties Manager
        if ($user.Manager) {
            return Get-ADUser $user.Manager
        }
        return $null
    }
    catch {
        Write-Error "Error getting manager for user $UserName : $_"
        return $null
    }
}