function Find-ADUser{
<#
    .SYNOPSIS
        Find-ADUser is a powershell function to assist in finding users.

    .DESCRIPTION
        Find-ADUser is a powershell function to assist in finding users.
        It does’t require any special binaries or components. It uses the underlying 
        Directory Services .Net classes which are available by default in any windows 
        system. 

    .PARAMETER username
        Specifies the username of the accout

    .EXAMPLE
        PS C:\>  Find-ADUser nathanaelries

#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$username,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )
$OFS = "`r`n"

$search = [adsisearcher]"(&(ObjectCategory=Person)(ObjectClass=User)(samaccountname=$username))"
$users = $search.FindAll()
foreach($user in $users) {
    $CN = $user.Properties['CN']
    $DisplayName = $user.Properties['DisplayName']
    $SamAccountName = $user.Properties['SamAccountName']
    $Group = $user.Properties['memberof']
    "CN is $CN"
    "Display Name is $DisplayName"
    "SamAccountName is $SamAccountName"
    ("Member of :"+$OFS+$Group-split ',')
}
}
