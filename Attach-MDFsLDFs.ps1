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
    
    $Attached = Get-SqlDatabase -ServerInstance $SQLServerInstance 

    $MDFs = get-childitem -Recurse $DatabaseDir *.mdf 
    $LDFs = get-childitem -Recurse $DatabaseDir *.ldf    
 
    foreach ($item in $MDFs){ 
        [bool]$ErrorExists = $false 
        $Item.name
        
        if($item.BaseName -in $Attached.Name){
                Write-Warning "This database already exists on the server" 
                $ErrorExists = $true 
        }
    
    if ($ErrorExists -eq $false){

        try {
            
            [IO.File]::OpenWrite($item.FullName).close();

        } catch { 
                Write-Warning "MDF was not able to be read. It is most likely already mounted or in use by another application" 
                $ErrorExists = $true 
        }
    }
            
    if ($ErrorExists -eq $false){ 
        Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue
        If (!$?) {Import-Module SQLPS -WarningAction SilentlyContinue}

        If (!$?) {"Error loading Microsoft SQL Server PowerShell module. Please check if it is installed."; Exit}
        
        $DBName = $item.BaseName
        $DbLocation = new-object System.Collections.Specialized.StringCollection 
        $mdfFilename = $item.fullname 
        $ldfFilename = ($LDFs.Where{$_.BaseName -like ($item.BaseName+"*")}).FullName

$attachSQLCMD = @"
USE [master]

CREATE DATABASE [$DBName] ON (FILENAME = '$mdfFilename'),(FILENAME = '$ldfFilename') for ATTACH
GO
"@ 
        Invoke-Sqlcmd $attachSQLCMD -QueryTimeout 3600 -ServerInstance $SQLServerInstance
        Write-Host -ForegroundColor Green "Database Attached"


    }
}

    
    return 
} 
