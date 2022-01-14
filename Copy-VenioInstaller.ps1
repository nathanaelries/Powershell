function Copy-VenioInstaller{
<#
    .SYNOPSIS
        Copy-VenioInstaller is a powershell function to assist in preparing for upgrading a Venio environment by copying the installer to the servers.
    .DESCRIPTION
       Copy-VenioInstaller is a powershell function to assist in preparing for upgrading a Venio environment by copying the installer to the servers.
        It has three required parameters (switches): -SQLServers -VenioRDS -XML
        and on optional parameter: Credential. Find the details of the parameters below.
    .PARAMETER SQLServers
        Specifies the computername of the SQL server(s) which should be hosting the project configuration databases.
    .Parameter VenioRDS
        Specifies the RDS (Desktop) of the venio environment. 
    .Parameter XML
        Specifies a required XML for automation. (See README_XML for more details)
    .Parameter Credential
        Specify the credenial to run the sql commands as a different user.
    .EXAMPLE
        PS C:\> Upgrade-VenioEnvironment -SQLServers server1,server2,server3 -VenioRDS VenioDesktop
#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string[]]$SQLServers,
    [Parameter(Mandatory=$true)][string]$VenioRDS,
    [Parameter(Mandatory=$true)][string]$XML,
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

    # Import arguments from an XML file (This XML should be created with the proper arguments prior to running. Arguments should be based on available options found with the /? switch on the installation .exe file provided by venio
    $ImportXML = Import-Clixml -Path $XML

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
    $tbl_ds_ServerDetail_Hostname = ($tbl_ds_ServerDetail.foreach({ <# Use the FQDN to alleviate issues and remove duplicates #> [System.Net.Dns]::GetHostByName($_.Hostname)}).HostName | Sort-Object -Unique)
    Write-Host $tbl_ds_ServerDetail_Hostname
    
        function Copy-ReadOnly
    {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    # Instantiate a buffer for the copy operation
    $Buffer = New-Object 'byte[]' 1024

    # Create a FileStream from the source path, make sure you open it in "Read" FileShare mode
    $SourceFile = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
    # Create the new file
    $DestinationFile = [System.IO.File]::Open($Destination,[System.IO.FileMode]::CreateNew)

    try{
        # Copy the contents of the source file to the destination
        while(($readLength = $SourceFile.Read($Buffer,0,$Buffer.Length)) -gt 0)
        {
            $DestinationFile.Write($Buffer,0,$readLength)
        }
    }
    catch{
        throw $_
    }
    finally{
        $SourceFile.Close()
        $DestinationFile.Close()
    }
}

    Workflow Prepare-VenioDirectory{



    param ([string[]]$tbl_ds_ServerDetail_Hostname,[string[]]$NetworkPath)


        # Foreach unique computer name in the ServerDetail table
        foreach -parallel ($Server in $tbl_ds_ServerDetail_Hostname)
        {
            # Cleanup the directory
            Remove-Item -Path "\\$Server\c$\Venio\9.4\" -Force -Recurse

            # Create folders
            foreach($folder in (gci $NetworkPath -Recurse -Directory).FullName){
                New-Item -Path \\$Server\c$\Venio\9.4\ -Name ($folder.replace($NetworkPath)) -ItemType Directory
            }
            
            # Copy files in read-only mode
            foreach($file in (gci $NetworkPath -File -Recurse).FullName){
               
                $sourcePath = (gci ($file)).fullname
                $dest = ("\\$Server\c$\Venio\9.4\"+ ($sourcePath.replace($NetworkPath))
                InlineScript {Write-Host "$using:sourcePath | $using:dest"}
                Copy-ReadOnly -Path $sourcePath -Destination $dest

            }# End copying files loop
        } # End parallel loop

    } # End Workflow Definition
       
    # Run workflow
    Prepare-VenioDirectory -tbl_ds_ServerDetail_Hostname $tbl_ds_ServerDetail_Hostname -NetworkPath $ImportXML.NetworkPath

} # End main
        
