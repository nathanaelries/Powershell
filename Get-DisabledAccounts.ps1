function Get-DisabledAccounts{
<#
    .SYNOPSIS
        Get-DisabledAccounts is a powershell function to assist in finding disabled user accounts.

    .DESCRIPTION
        Get-DisabledAccounts is a powershell function to assist in finding disabled user accounts.
        It has one required parameters (switches): -DC
        And two optional parameters, TimeSpan and Credential. Find the details of the parameters below.

    .PARAMETER DC
        Specifies the domain controller to use.

    .Parameter TimeSpan
        Specifies the maximum number of days back in time to search.

    .Parameter Credential
        Specify the credenial to run the commands as a different user.

    .EXAMPLE
        PS C:\> Get-DisabledAccounts DOMAINCONTROLLER 30

#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$DC,
    [Parameter(Mandatory=$false)][int16]$TimeSpan,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )

    if($TimeSpan -and $TimeSpan -ge 0){$TimeSpan = 0 - $TimeSpan}

    $count = (Search-ADAccount -AccountDisabled -UsersOnly).count
    $DisabledUsers = Get-ADObject -Filter "ObjectClass -eq 'USER' -and userAccountControl -eq '514'" 

    $Results = @()
    $x = 0

    foreach($DisabledUser in $DisabledUsers){
        
        $i = [int]($X++/$count*100)
        Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i;

        $Results += Get-ADReplicationAttributeMetadata $DisabledUser -Server $DC |
            Where-Object {$_.AttributeName -eq 'UserAccountControl'} | Select Object,LastOriginatingChangeTime |
                Where-Object {$_.LastOriginatingChangeTime -gt (Get-Date).AddDays($TimeSpan)}
    }

    Return $Results
}
