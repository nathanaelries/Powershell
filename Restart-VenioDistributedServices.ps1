function Restart-VenioDistributedServices{
<#
    .SYNOPSIS
        Restart-VenioDistributedServices is a powershell function to assist in restarting distributed services.
    .DESCRIPTION
       Restart-VenioDistributedServices is a powershell function to assist in restarting distributed services.
        It has two required parameters (switches): -SQLServers -VenioRDS 
        and on optional parameter: Credential. Find the details of the parameters below.
    .PARAMETER SQLServers
        Specifies the computername of the SQL server(s) which should be hosting the project configuration databases.
    .Parameter VenioRDS
        Specifies the RDS (Desktop) of the venio environment. 
    .Parameter Credential
        Specify the credenial to run the sql commands as a different user.
    .EXAMPLE
        PS C:\> Restart-VenioDistributedServices -SQLServers server1,server2,server3 -VenioRDS VenioDesktop
#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string[]]$SQLServers,
    [Parameter(Mandatory=$true)][string]$VenioRDS,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )

    # Load the assemblies
    [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
    [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")
    $OFS = "`r`n"

    # Define array store the information of all of the  project databases into an array by running the $DatabaseInstanceNameQuery
    $DatabaseInstanceNameArray = @()

    # Define the output object array to store the results
    $OutputObj = @()

    # Define query for getting information for each venio project database
    $DatabaseInstanceNameQuery = 'SELECT ProjectName, DatabaseInstanceName, @@servername as ServerInstance, DB_NAME() AS [PCD] FROM [dbo].[tbl_pj_ProjectSetup]'
       
    # Find all databases on the server with "PCD" in the database name
    $PCDInstanceName = Foreach($Server in $SQLServers){
        (Get-WmiObject -Query "select * from win32_service where PathName like '%%sqlservr.exe%%'" -ComputerName $Server).foreach{
            $_ | Add-Member -NotePropertyName Server -NotePropertyValue $Server
        
            if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
                $Results = Invoke-Sqlcmd -Query "Select @@servername as ServerInstance, name as PCD from Sys.Databases WHERE name like '%PCD%'" -ServerInstance ($_.Server+'\'+$_.DisplayName -replace "SQL Server \(" -replace'\)') -ErrorAction SilentlyContinue -ErrorVariable NoProjectSetupTable -Credential $Credential
            } else {
                $Results = Invoke-Sqlcmd -Query "Select @@servername as ServerInstance, name as PCD from Sys.Databases WHERE name like '%PCD%'" -ServerInstance ($_.Server+'\'+$_.DisplayName -replace "SQL Server \(" -replace'\)') -ErrorAction SilentlyContinue -ErrorVariable NoProjectSetupTable 
            }
            if ($NoProjectSetupTable){<# Nothing to do here, database Does not appear to contain a ProjectSetup table"#>
            } else {
                $tbl_ds_ServerDetail = Invoke-Sqlcmd -ServerInstance $Results.ServerInstance -Database $Results.PCD -Query 'SELECT DISTINCT [Hostname],[Application] FROM [tbl_sys_ComponentVersionInfo] with (NOLOCK)' -ErrorAction SilentlyContinue -ErrorVariable NoServerDetailTable -QueryTimeout 65534
            }}

            if($tbl_ds_ServerDetail.Hostname -contains $VenioRDS){

            # Foreach distributed server in the environment
            foreach ($Server in $tbl_ds_ServerDetail.Hostname){

                # Check for existence of the venio search service
                $SearchServiceExists = $false
                $SearchServiceExists = (get-service -ComputerName $Server -Name 'VenioSearchService' -ErrorAction SilentlyContinue)

                # Check for existence of the venio Distributed service
                $DistributedServiceExists = $false
                $DistributedServiceExists = (get-service -ComputerName $Server -Name 'VenioDistributedService' -ErrorAction SilentlyContinue)
                
                # Check for existence of the venio FPR 
                $FPRProcExists = $false
                $FPRProcExists = (Get-WmiObject Win32_Process -ComputerName $Server -ErrorAction SilentlyContinue | ?{ $_.ProcessName -like "*FPR*" }-ErrorAction SilentlyContinue) 

                # Check for existence of the venio search service, and stop if found
                if ($DistributedServiceExists){
                Write-warning "Stopping Venio Distributed Service on $Server"
                (get-service -ComputerName $Server -Name 'VenioDistributedService').Stop()
                (get-service -ComputerName $Server -Name 'VenioDistributedService').WaitForStatus('Stopped')
                (get-service -ComputerName $Server -Name 'VenioDistributedService').Status
                # 1. close the distributed service executable
                Write-Warning ("Closing VenioDistributedService processes on "+$Server+"")
                $proc = Get-Process -ComputerName $Server
                while ($proc.Name -contains 'VenioDistributedService'){
                (Get-WmiObject Win32_Process -ComputerName $Server | ?{ $_.ProcessName -like "*DistributedService*" }).Terminate()
                Start-Sleep -Seconds 1
                $proc = Get-Process -ComputerName $Server
                }# 3. Start Distributed Service
                (get-service -ComputerName $Server -Name 'VenioDistributedService').Start()
                (get-service -ComputerName $Server -Name 'VenioDistributedService').WaitForStatus('Running')
                (get-service -ComputerName $Server -Name 'VenioDistributedService').Status
                Write-Host "SUCCESS: Venio Distributed Service is now running on $Server" -BackgroundColor Green -ForegroundColor Black


                # Check for existence of the venio search service, and stop if found
                }if ($SearchServiceExists){
                Write-warning "Stopping Venio Search Service on $Server"
                (get-service -ComputerName $Server -Name 'VenioSearchService').Stop()
                (get-service -ComputerName $Server -Name 'VenioSearchService').WaitForStatus('Stopped')
                (get-service -ComputerName $Server -Name 'VenioSearchService').Status
                # 1. close the distributed service executable
                Write-Warning ("Closing VenioDistributedService processes on "+$Server+"")
                $proc = Get-Process -ComputerName $Server
                while ($proc.Name -contains 'VenioDistributedService'){
                (Get-WmiObject Win32_Process -ComputerName $Server | ?{ $_.ProcessName -like "*DistributedService*" }).Terminate()
                Start-Sleep -Seconds 1
                $proc = Get-Process -ComputerName $Server
                #start the search service
                }(get-service -ComputerName $Server -Name 'VenioSearchService').Start()
                (get-service -ComputerName $Server -Name 'VenioSearchService').WaitForStatus('Running')
                (get-service -ComputerName $Server -Name 'VenioSearchService').Status
                Write-Host "SUCCESS: Venio Search Service is now running on $Server $OFS" -BackgroundColor Green -ForegroundColor Black

                }if ($FPRProcExists){<# Do stuff on the RDS #>}                
            }
        }
    }
}





