
# user inputs (Change these!)
$findstr = ''
$replacestr = ''
$serverinstance = 'server\instance'
$prj_databasename = ''

# do not change anything past this point!

# Set the output field separator to standard dos carriage return and newline
$OFS = "`r`n"

# Display instructions for executing script
Clear-Host;Write-Warning "Please run from an account with admin rights $OFS"
write-host "Current User: $env:USERDOMAIN\$env:USERNAME$OFS"

# Display instructions for executing script
Write-Warning "Make sure you have modified this script to the proper user inputs before running!$OFS"

<#TEST
# user inputs (Change these!)
$findstr = ''
$replacestr = ''
$serverinstance = ''
$prj_databasename = ''

#>

write-host @" 
Current user inputs: 

`$findstr = '$findstr'
`$replacestr = '$replacestr'
`$serverinstance = '$serverinstance'
`$prj_databasename = '$prj_databasename'

"@

if(!$findstr -or !$replacestr -or !$serverinstance -or !$prj_databasename ){Write-Warning "User inputs blank!$OFS"
$host.enternestedprompt()

}

pause

# Define pathFields
$pathFields = @()
function Add-PathField
{
    Param
    (
         [Parameter(Mandatory=$true, Position=1)]
         [string] $name,
         [Parameter(Mandatory=$true, Position=0)]
         [string] $table,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $pk
    )

    [hashtable]$TableInfo = @{}

    $TableInfo.Add('name',$name)
    $TableInfo.Add('table',$table)
    $TableInfo.Add('pk',$pk)

    $Result = New-Object -TypeName psobject -Property $TableInfo
    return $Result
}

$pathFields += Add-PathField -name AccessPath -table tbl_ex_FileInfo -pk FileID
$pathFields += Add-PathField -name AbsoluteFilePath -table tbl_ex_FileInfo -pk FileID
$pathFields += Add-PathField -name OriginalFilePath -table tbl_ex_FileInfo -pk FileID
$pathFields += Add-PathField -name OriginalAccessPath -table tbl_ex_FileInfo -pk FileID
$pathFields += Add-PathField -name IndexLocation -table tbl_ex_Media -pk MediaID
$pathFields += Add-PathField -name FileLocation -table tbl_ex_Media -pk MediaID
$pathFields += Add-PathField -name FullTextFileLocation -table tbl_ex_FulltextFileLocation -pk FileID 
$pathFields += Add-PathField -table tbl_ep_tiffexportdetails -name PreservedExportLocation
$pathFields += Add-PathField -table tbl_ex_ConvertedDXLFileLocation -name DXLFileLocation
$pathFields += Add-PathField -table tbl_ex_ConvertedDXLFileLocation -name DXLFileLocationWithMimeData
$pathFields += Add-PathField -table tbl_ex_HiddenFulltextFileLocation -name HiddenFulltextFileLocation
$pathFields += Add-PathField -table tbl_ex_MediaSourceAssociation -name BaseFolder
$pathFields += Add-PathField -table tbl_ex_MediaSourceAssociation -name Source 
$pathFields += Add-PathField -table tbl_ex_RTFFileLocation -name RTFFileLocation 
$pathFields += Add-PathField -table tbl_ft_ImageFullText -name RedactedOCRFulltextFileLocation 
$pathFields += Add-PathField -table tbl_ft_ImageFullText -name TiffOCRFulltextFileLocation 
$pathFields += Add-PathField -table tbl_ig_MediaCopyStatus -name sourcepath 
$pathFields += Add-PathField -table tbl_ig_MediaCopyStatus -name UniqueIdentifier 
$pathFields += Add-PathField -table tbl_ig_MediaCopyStatus -name uploadpath 
$pathFields += Add-PathField -table tbl_imp_ImportDetails -name ImportLogFolder 
$pathFields += Add-PathField -table tbl_ocr_Shadow -name FulltextLocation 
$pathFields += Add-PathField -table tbl_ocr_Shadow -name UNCFile 
$pathFields += Add-PathField -table tbl_pj_ProjectSetup -name FileServerLocation 
$pathFields += Add-PathField -table tbl_pj_ProjectSetup -name IndexLocation 
$pathFields += Add-PathField -table tbl_ps_ScanFileInfo -name FileFullPath 
$pathFields += Add-PathField -table tbl_ps_ScanFileInfo -name UniqueIdentifier 
$pathFields += Add-PathField -table tbl_rev_FileInfo -name FullTextFileLocation 
$pathFields += Add-PathField -table tbl_rev_FileInfo -name NativeFileLocation 
$pathFields += Add-PathField -table tbl_rev_FileInfo -name OriginalFilePath 
$pathFields += Add-PathField -table Tbl_tiff_Images -name ImagePath 
$pathFields += Add-PathField -table Tbl_tiff_Images -name RedactedImagePath 
$pathFields += Add-PathField -table tbl_tiff_Shadow -name uncfile 
$pathFields += Add-PathField -table tbl_VAR_DF_Files -name DFFile 
$pathFields += Add-PathField -table tbl_var_Model_Files -name ModelFile 
$pathFields += Add-PathField -table tbl_VAR_Problem_Files -name ProblemFile 
$pathFields += Add-PathField -table tbl_VAR_ProfileInfo -name ProfileFolder 
$pathFields += Add-PathField -table tbl_VAR_tf_files -name TFFile 



# Define query for getting information for each venio project database
$DatabaseInstanceNameQuery = @"
SELECT DatabaseInstanceName, @@servername as ServerInstance, DB_NAME() AS [Database]
FROM [tbl_pj_ProjectSetup] 
"@

# Define query for find replace
function ConvertTo-SQLReplaceFieldValues(){
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$ins,
        [string]$dbo,
        [string]$field,
        [string]$tbl,
        [string]$replace,
        [switch]$Validate=$false
    )

$SQL = @"
UPDATE [$dbo].[dbo].[$tbl]
SET $field = REPLACE($field,$replace)
"@

Write-Host $SQL
return $SQL
}

$FIELD_COUNT = 0

# Inner loop foreach field with paths that may need updating
foreach($field in $pathFields){
    
Write-Progress -id 2 -activity ("replacing old paths in "+$field.name+" "+$field.table+" . . .") -status "Updated: $FIELD_COUNT of $($pathFields.Count)" -percentComplete (($FIELD_COUNT++ / $pathFields.Count)  * 100)

    # Create the find replace query  
    Write-Host "Finding and replacing strings in path fields"
    Invoke-Sqlcmd -ServerInstance $serverinstance -Query (ConvertTo-SQLReplaceFieldValues -ins $serverinstance -dbo $prj_databasename -tbl $field.table -field $field.name -replace "'$findstr','$replacestr'")
    
}
Write-Progress -id 2 -activity ("replacing old paths in "+$field.name+" "+$field.table+" . . .") -status "Updated: $FIELD_COUNT of $($pathFields.Count)" -Completed
