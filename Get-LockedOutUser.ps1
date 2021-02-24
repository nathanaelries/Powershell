function Get-LockedOutUSer{
     <#
    .SYNOPSIS
        Get-LockedOutUSer is a powershell function to try to diagnose account lockouts for specific users.
    .DESCRIPTION
        Get-LockedOutUSer is a powershell function to try to diagnose account lockouts for specific users.
        It has one required parameter (switch): -Username
        And two optional parameters, -Credential 
    .PARAMETER Username
        Specifies the AD user logon name of the AD user who has been experiencing account lockouts
    .Parameter Credential
        Specify the credenial to run the AD commands as a different user.
    .Parameter -StartTime
        Specify how many days to go back into the logs on the domain controller
    .EXAMPLE
        PS C:\> Get-LockedOutUSer -Username ALICE -Credential (Get-Credential) -StartTime ((Get-Date).AddDays(-7))
    #>

    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$Username,
    [ValidateNotNullOrEmpty()]
    [datetime]$StartTime = (Get-Date).AddDays(-1),
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )

write-host please wait while domain controllers are found
$DomainControllers = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites | % { $_.Servers } | select Domain,Name,SiteName

foreach($DC in $DomainControllers){
Write-host ("checking "+$DC.name)
Invoke-Command -ComputerName ($DC.name) {
    Get-WinEvent -FilterHashtable @{LogName='Security';Id=4740;StartTime=$Using:StartTime} |
    Where-Object {$_.Properties[0].Value -like "$Using:UserName"} |
    Select-Object -Property TimeCreated,
        @{Label='UserName';Expression={$_.Properties[0].Value}},
        @{Label='ClientName';Expression={$_.Properties[1].Value}}
} -Credential $Credential |
Select-Object -Property TimeCreated, UserName, ClientName
}
}
