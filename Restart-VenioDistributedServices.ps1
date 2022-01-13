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

    $tbl_ds_ServerDetail = @()

    # Define the output object array to store the results
    $OutputObj = @()

    # Define query for getting information for each venio project database
    $DatabaseInstanceNameQuery = 'SELECT ProjectName, DatabaseInstanceName, @@servername as ServerInstance, DB_NAME() AS [PCD] FROM [dbo].[tbl_pj_ProjectSetup]'
    
    # Find all databases on the server(s) with "PCD" in the database name
    $PCDInstanceName = Foreach($Server in $SQLServers){
        [System.Management.Automation.PSObject]$SQL_Service = $null
        [System.Management.Automation.PSObject]$SQL_Service = (Get-WmiObject -Query "select * from win32_service where PathName like '%%sqlservr.exe%%'" -ComputerName $Server)
        Foreach($Service in $SQL_Service){
            $Service | Add-Member -NotePropertyName Server -NotePropertyValue $Server
            if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
                try{
                $Results = Invoke-Sqlcmd -DisableVariables -Query "Select @@servername as ServerInstance, name as PCD from Sys.Databases WHERE name like '%PCD%'" -ServerInstance ($Service.Server+'\'+$Service.DisplayName -replace "SQL Server \(" -replace'\)') -ErrorAction SilentlyContinue -ErrorVariable NoProjectSetupTable -Credential $Credential
                }catch{}
            } else {
                try{
                $Results = Invoke-Sqlcmd -DisableVariables -Query "Select @@servername as ServerInstance, name as PCD from Sys.Databases WHERE name like '%PCD%'" -ServerInstance ($Service.Server+'\'+$Service.DisplayName -replace "SQL Server \(" -replace'\)') -ErrorAction SilentlyContinue -ErrorVariable NoProjectSetupTable 
                }catch{}
            }
            if ($NoProjectSetupTable){<# Nothing to do here, database Does not appear to contain a ProjectSetup table"#>
            } else {
                
                # Find all workers in each PCD
                foreach($Result in $Results){
                $temp_tbl_ds_ServerDetail = $null
                $temp_tbl_ds_ServerDetail = Invoke-Sqlcmd -DisableVariables -ServerInstance $Result.ServerInstance -Database $Result.PCD -Query 'SELECT DISTINCT [Hostname],[Application] FROM [tbl_sys_ComponentVersionInfo] with (NOLOCK) where [LoggedDate]  >=  (getdate()-366)' -ErrorAction SilentlyContinue -ErrorVariable NoServerDetailTable -QueryTimeout 65534
                # only add server details for environment matching the RDS specified by the user 
            if($temp_tbl_ds_ServerDetail.Hostname -contains $VenioRDS){$tbl_ds_ServerDetail += $temp_tbl_ds_ServerDetail}
            }}}}
                   
    # Output the unique names of the RDS and workers found
    $tbl_ds_ServerDetail_Hostname = ($tbl_ds_ServerDetail.Hostname | Sort-Object -Unique)
    Write-Host $tbl_ds_ServerDetail_Hostname
    
    workflow Workflow-VenioServers {

    param ([string[]]$tbl_ds_ServerDetail_Hostname)

    # Foreach unique computer name in the ServerDetail table
    foreach -parallel ($Server in $tbl_ds_ServerDetail_Hostname){

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
            "Distributed Service Detected on $Server"
            
            InlineScript {
                Write-Host "$Using:Server VenioDistributedService [STOPPING]"
                # send the command to stop the service
                (get-service -ComputerName $Using:Server -Name 'VenioDistributedService').Stop()
                # Force close the distributed service executable
                $proc = (Get-WmiObject Win32_Process -ComputerName $Using:Server)
                while ($proc.Name -contains 'VenioDistributedService'){
                    (Get-WmiObject Win32_Process -ComputerName $Using:Server | ?{ $_.ProcessName -like "*DistributedService*" }).Terminate()
                    Start-Sleep -Seconds 1
                    $proc = (Get-WmiObject Win32_Process -ComputerName $Using:Server)             
                }
                # Wait until service is stopped
                (get-service -ComputerName $Using:Server -Name 'VenioDistributedService').WaitForStatus('Stopped')
                Write-Host "$Using:Server VenioDistributedService [STOPPED]"

                # 3. Start Distributed Service
                (get-service -ComputerName $Using:Server -Name 'VenioDistributedService').Start()
                (get-service -ComputerName $Using:Server -Name 'VenioDistributedService').WaitForStatus('Running')
                 Write-Host "$Using:Server VenioDistributedService [RUNNING]"
             } # End InlineScript
        }
        #>
        # Check for existence of the venio search service, and stop if found
        if ($SearchServiceExists){
            "Search Service Detected on $Server"
            InlineScript {
                Write-Host "$Using:Server VenioSearchService [STOPPING]"
                (get-service -ComputerName $Using:Server -Name 'VenioSearchService').Stop()
                (get-service -ComputerName $Using:Server -Name 'VenioSearchService').WaitForStatus('Stopped')
                Write-Host "$Using:Server VenioSearchService [STOPPED]"
                # 1. close the distributed service executable
                $proc = (Get-WmiObject Win32_Process -ComputerName $Using:Server)
                while ($proc.Name -contains 'VenioSearchService'){
                    (Get-WmiObject Win32_Process -ComputerName $Using:Server | ?{ $_.ProcessName -like "*VenioSearch*" }).Terminate()
                    Start-Sleep -Seconds 1
                    $proc = (Get-WmiObject Win32_Process -ComputerName $Using:Server)
                }
                #start the search service
                (get-service -ComputerName $Using:Server -Name 'VenioSearchService').Start()
                (get-service -ComputerName $Using:Server -Name 'VenioSearchService').WaitForStatus('Running')
                Write-Host "$Using:Server VenioSearchService [RUNNING]"
            }
        }

        # Do stuff on the RDS 
        if ($FPRProcExists){
                "FPR Detected on $Server"}

        # else{Restart-Computer -PSComputerName $server -Force} # Do stuff on every worker except the RDS            
    }
    } # END Workflow definition
    
    # execute workflow
    Workflow-VenioServers -tbl_ds_ServerDetail_Hostname $tbl_ds_ServerDetail_Hostname
    
} # End function definition
