function Logoff-UserAcrossDomain{
     <#
    .SYNOPSIS
        Logoff-UserAcrossDomain is a powershell function to logout a specified user from all computers accros a domain.
    .DESCRIPTION
        Logoff-UserAcrossDomain is a powershell function to logout a specified user from all computers accros a domain.
        It has one required parameter (switch): -ADLogonName
        And two optional parameters, -Credential and -ExcludeComputer. Find the details of the parameters below.
    .PARAMETER ADLogonName
        Specifies the AD user logon name of the AD user to logout.
    .Parameter Credential
        Specify the credenial to run the AD commands as a different user.
    .Parameter -Exclude
        Specify computer(s) to exclude from logging off (example: -Exclude $env:COMPUTERNAME)
        You can specify multiple computer names seperated by commas (example: -Exclude $env:COMPUTERNAME,COMP-01,COMPUTER2)
    .EXAMPLE
        PS C:\> Logoff-UserAcrossDomain -ADLogonName ALICE -Credential (Get-Credential)
    #>

    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$ADLogonName,
    [Parameter(Position = 1,Mandatory=$false)][string[]]$Exclude,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )
    # List all Domain Controllers, Servers, and non-server computers
    if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
    [System.Collections.ArrayList]$Computers =  Get-ADComputer -Filter 'enabled -eq "true"' -Credential $Credential `
    -Properties Name,Operatingsystem,OperatingSystemVersion |
    Sort-Object -Property OperatingsystemVersion |
    Select-Object -ExpandProperty Name
    }else{
    [System.Collections.ArrayList]$Computers =  Get-ADComputer -Filter 'enabled -eq "true"' `
    -Properties Name,Operatingsystem,OperatingSystemVersion |
    Sort-Object -Property OperatingsystemVersion |
    Select-Object -ExpandProperty Name
    }

    # Remove excluded computer(s) from list
    foreach($computer in $exclude){
    $Computers.RemoveAt($Computers.IndexOf($Computers.where({$_ -eq $computer})))
    }

    # Create Error Log Array
    $ErrorLog = @()

     ## Run through all the computers in the array
     foreach($Computer in $Computers){
     $computer

        ## Find all sessions matching the specified username
        $Procs = $null
        $SessionIDs = @()
        $Object = $null
        try{
        if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $Procs = Invoke-Command $Computer -ErrorAction Stop -Credential $Credential -ScriptBlock{Get-Process -IncludeUserName -Name taskhost | Where-Object {$_.username -match "$ADLogonName"}} 
        } else {
        $Procs = Invoke-Command $Computer -ErrorAction Stop -ScriptBlock{Get-Process -IncludeUserName -Name taskhost | Where-Object {$_.username -match "$ADLogonName"}} 
        }
        If ($Procs) {
            Foreach ($P in $Procs) {
                $Object = New-Object PSObject -Property ([ordered]@{    
                            "SessionID"              = $P.SessionID
                })
            $SessionIDs += $Object
            }
        }
        Write-Host "Found $(@($sessionIds.SessionID).Count) user login(s) on computer."
        ## Loop through each session ID and pass each to the logoff command
        $sessionIds | ForEach-Object {
            Write-Host "Logging off session id [$($_.SessionID)]..."
            if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            Invoke-Command $Computer -ErrorAction Stop -Credential $Credential -ScriptBlock{logoff.exe $_.SessionID}
            } else {
            Invoke-Command $Computer -ErrorAction Stop -ScriptBlock{logoff.exe $_.SessionID}
            }
        }
        } catch {  
           
        }

    }

}
