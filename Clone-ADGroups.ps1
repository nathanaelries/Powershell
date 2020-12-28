
function Clone-ADGroups{
    <#
    .SYNOPSIS
        Clone-ADGroups is a powershell function to clone an existing user's groups into another existing user's groups.
    .DESCRIPTION
        Clone-ADGroups is a powershell function to clone an existing user's groups into another existing user's groups.
        It has two required parameters (switches): -CloneFrom -CloneInto
        And one optional parameter, -Credential. Find the details of the parameters below.
    .PARAMETER CloneFrom
        Specifies the user logon name of the existing user to clone all of the groups from.
    .Parameter CloneIngo
        Specifies the destination user logon name of the existing user to add to the groups the CloneFrom user is already assigned to.
    .Parameter Credential
        Specify the credenial to run the AD commands as a different user.
    .EXAMPLE
        PS C:\> Clone-ADGroups ALICE,BOB
#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$CloneFrom,
    [Parameter(Position = 1,Mandatory=$true)][string]$CloneInto,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )
    Import-Module ActiveDirectory
    if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        Get-ADUser -identity $CloneFrom -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $CloneInto -Credential $Credential -Passthru | Format-Table -Property Name,GroupCategory,GroupScope,DistinguishedName -AutoSize
    } elese {
        Get-ADUser -identity $CloneFrom -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $CloneInto | Format-Table -Property Name,GroupCategory,GroupScope,DistinguishedName -AutoSize
    }
}
