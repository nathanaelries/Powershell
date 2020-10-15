function Find-EcaptureProjects{
<#
    .SYNOPSIS
        Find-EcaptureProjects is a powershell function to assist in finding ecapture databases.

    .DESCRIPTION
        Find-EcaptureProjects is a powershell function to assist in finding ecapture databases.
        It has one required parameters (switches): -SQLServers
        And two optional parameters, ProjectName and Credential. Find the details of the parameters below.

    .PARAMETER SQLServers
        Specifies the computername of the SQL server(s) which should be hosting the project configuration databases.

    .Parameter ProjectName
        Specifies the name of the project to search for.

    .Parameter Credential
        Specify the credenial to run the sql commands as a different user.

    .EXAMPLE
        PS C:\> Find-EcaptureProjects server1,server2,server3 PROJ0001

#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string[]]$SQLServers,
    [Parameter(Mandatory=$false)][string]$ProjectName,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )

    # Define array store the information of all of the  project databases into an array by running the $DatabaseInstanceNameQuery
    $DatabaseInstanceNameArray = @()

    # Define the output object array to store the results
    $OutputObj = @()

    # Define query for getting information for each venio project database
    $DatabaseInstanceNameQuery = 'SELECT ClientName, ClientDatabase, @@servername as ServerInstance, DB_NAME() AS [ConfigDB] FROM [dbo].[Clients]'

    # Find all databases on the server with "Config" in the database name
    $ConfigInstanceName = @($SQLServers | Foreach-Object {(Get-ChildItem -Path "SQLSERVER:\SQL\$_").Name}).ForEach({
        if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            Invoke-Sqlcmd -Query "Select @@servername as ServerInstance, name as PEDDConfig from Sys.Databases WHERE name not like '%Client00%' and name like '%config%'" -ServerInstance $_ -Credential $Credential
        }
        else {
            Invoke-Sqlcmd -Query "Select @@servername as ServerInstance, name as PEDDConfig from Sys.Databases WHERE name not like '%Client00%' and name like '%config%'" -ServerInstance $_
        }
    })

    # Find all of the project databases listed in each of the PEDDConfig databases
    $ConfigInstanceName.ForEach({
            
        # Define the temp object to add to the output object array
        $TempOutputObj = @()

        if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            $Results = Invoke-Sqlcmd -Query $DatabaseInstanceNameQuery -ServerInstance $_.ServerInstance -Database $_.PEDDConfig -ErrorAction SilentlyContinue -ErrorVariable NoClientsTable -Credential $Credential
        }else{
            $Results = Invoke-Sqlcmd -Query $DatabaseInstanceNameQuery -ServerInstance $_.ServerInstance -Database $_.PEDDConfig -ErrorAction SilentlyContinue -ErrorVariable NoClientsTable
        }
        
        if ($NoClientsTable){<# Nothing to do here, database Does not appear to contain a clients table"#>}

        else {
            $DatabaseInstanceNameArray = $DatabaseInstanceNameArray + ($Results)
            $TempOutputObj += New-Object -TypeName psobject -Property @{ClientName=$null;ClientDatabase=$null;ServerInstance=$_.ServerInstance; ConfigDB=$_.PEDDConfig; Attached=$true}
            $OutputObj += $TempOutputObj
            Write-Host ("Potential ecapture configuration database found: "+$_.PEDDConfig+" on "+$_.ServerInstance)}
    })

    if ($ProjectName){
        $DatabaseInstanceNameMatches = $DatabaseInstanceNameArray.Where({$_.ClientName -like "*$ProjectName*"})
    }else{$DatabaseInstanceNameMatches=$DatabaseInstanceNameArray}

    $OutputObj += $DatabaseInstanceNameMatches

    Return $OutputObj
}
