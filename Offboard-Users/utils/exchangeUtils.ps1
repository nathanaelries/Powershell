function Remove-CalendarMeetings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail
    )
    
    try {
        $meetings = Get-CalendarItems -Mailbox $UserEmail
        foreach ($meeting in $meetings) {
            Remove-CalendarItem -Identity $meeting.Identity -Confirm:$false
        }
        Write-Host "Successfully removed calendar meetings for $UserEmail"
    }
    catch {
        Write-Error "Error removing calendar meetings for $UserEmail : $_"
    }
}

function Set-MailboxDelegation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerEmail
    )
    
    try {
        Add-MailboxPermission -Identity $UserEmail -User $ManagerEmail -AccessRights FullAccess -InheritanceType All
        Write-Host "Successfully delegated mailbox access to manager"
    }
    catch {
        Write-Error "Error setting mailbox delegation: $_"
    }
}