function Disable-UserAccount {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $true)]
        [string]$DisabledOU
    )
    
    try {
        # Disable the user account
        Disable-ADAccount -Identity $UserName
        Write-Host "Successfully disabled user account: $UserName"
        
        # Update description with disabled date
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        Set-ADUser -Identity $UserName -Description "Disabled on $currentDate"
        
        # Move to Disabled OU
        $user = Get-ADUser $UserName
        Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
        Write-Host "Successfully moved user to Disabled OU"
        
        return $true
    }
    catch {
        Write-Error "Error disabling user account: $_"
        return $false
    }
}

function Remove-SecurityGroups {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    try {
        $user = Get-ADUser $UserName -Properties MemberOf
        $groups = $user.MemberOf | Where-Object { 
            $_ -notmatch "Domain Users"
        }
        
        foreach ($group in $groups) {
            Remove-ADGroupMember -Identity $group -Members $UserName -Confirm:$false
        }
        Write-Host "Successfully removed security groups"
    }
    catch {
        Write-Error "Error removing security groups: $_"
    }
}