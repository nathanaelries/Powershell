function Attach-MDFsLDFs {
<#
    .SYNOPSIS
        Attach-MDFsLDFs is a powershell function to attach all unattached mdf and log files

    .DESCRIPTION
        Attach-MDFsLDFs is a powershell function to attach all unattached mdf and log files
        It has two required parameters (switches): -SQLServerInstance -DatabaseDir
        And one optional parameter, Credential. Find the details of the parameters below.

    .PARAMETER SQLServerInstance
        Specifies the computername and instance of SQL where databases will be attached.

    .Parameter DatabaseDir
        Specifies the parent dir containing the database and log files.
        
    .Parameter Credential
        Specify the credenial to run the sql commands as a different user.

    .EXAMPLE
        PS C:\> Attach-MDFsInDir server\instance X:\DB_File_Dir\
#>
    [CmdletBinding()]
    param(
    [Parameter(Position = 0,Mandatory=$true)][string]$SQLServerInstance,
    [Parameter(Mandatory=$true)][string]$DatabaseDir,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )
    
    # Get all the attached databases
    if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $Attached = Get-SqlDatabase -ServerInstance $SQLServerInstance -Credential $Credential
    }else{$Attached = Get-SqlDatabase -ServerInstance $SQLServerInstance }

    # Find all mdf and ldf in directory
    $MDFs = get-childitem -Recurse $DatabaseDir *.mdf
    $LDFs = get-childitem -Recurse $DatabaseDir *.ldf    
    
    foreach ($item in $MDFs){ 
        # Error Variable
        [bool]$ErrorExists = $false 

        # Output current mdf file name
        $Item.name

        # Check if already attached
        if($item.BaseName -in $Attached.Name){
                Write-Warning "This database already exists on the server" 
                $ErrorExists = $true 
        }
        
        if ($ErrorExists -eq $false){

        # Check if file is locked
        try {
            
            [IO.File]::OpenWrite($item.FullName).close();

        } catch { 
                Write-Warning "MDF was not able to be read. It is most likely already mounted or in use by another application" 
                $ErrorExists = $true 
        }
        }
            
        if ($ErrorExists -eq $false){ 

        # Make sure the PSSnapin is available
        Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue
        If (!$?) {Import-Module SQLPS -WarningAction SilentlyContinue}
        If (!$?) {"Error loading Microsoft SQL Server PowerShell module. Please check if it is installed."; Exit}
        
        # Set the dbname, mdf fullname, and ldf fullname
        $DBName = $item.BaseName
        $mdfFilename = $item.fullname 
        $ldfFilename = ($LDFs.Where{$_.BaseName -like ($item.BaseName+"*")}).FullName

# Generate SQL query to attach databases.
$attachSQLCMD = @"
USE [master]

CREATE DATABASE [$DBName] ON (FILENAME = '$mdfFilename'),(FILENAME = '$ldfFilename') for ATTACH
GO
"@ 
        #Run the generated query
        if($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        Invoke-Sqlcmd $attachSQLCMD -QueryTimeout 3600 -ServerInstance $SQLServerInstance -Credential $Credential
        }else{Invoke-Sqlcmd $attachSQLCMD -QueryTimeout 3600 -ServerInstance $SQLServerInstance}

        Write-Host -ForegroundColor Green "Database Attached"
        }
    }
    return 
} 
