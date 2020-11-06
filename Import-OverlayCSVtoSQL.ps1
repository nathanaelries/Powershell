$ServerInstance = "LEGUS-SQL-MI01\INSTANCEA"
$Database = "prj_SCOx0001_SGSS_MINDSEYE_1382"
$LoadfilePath = "C:\Users\nd-admin\Desktop\test.csv"

$ImportedLoadfile = Import-Csv -Path $LoadfilePath -Delimiter "`t"

# get the loadfile headers and store them as fields
$LoadfileFields = $ImportedLoadfile | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

$SQLFieldPlaceholder = @()

$OFS = "`r`n"

$SQLSelect = @"
SELECT  
"@

$SQLFrom = @"
FROM 
"@

$SQLJoins = @"
WHERE 
"@

$SQLWhere = @"
AND 
"@

$X = 1
$SQLFieldPlaceholder = @()
$SQLValuePlaceholder = @()
$SQLTablePlaceholder = @()
$SQLJoinsPlaceholder = @()

function Generate-SelectStatement($Field,$Int){
return ("F"+'{0:d3}' -f $Int+".$field as F"+'{0:d3}' -f $Int+"$field")
}
# Generate a select statement
foreach($LFfield in $LoadfileFields){
# Generate a select statement
$SQLFieldPlaceholder +=  Generate-SelectStatement -Field TABLE_CATALOG -Int $X
$SQLFieldPlaceholder +=  Generate-SelectStatement -Field TABLE_NAME -Int $X
$SQLFieldPlaceholder +=  Generate-SelectStatement -Field COLUMN_NAME -Int $X

#Generate FROM clause
$SQLTablePlaceholder += ("INFORMATION_SCHEMA.COLUMNS F"+'{0:d3}' -f $X)

# Generate where
$SQLJoinsPlaceholder +=  ("F001.TABLE_NAME = F"+'{0:d3}' -f $X+".TABLE_NAME ")

# Generate and
$SQLValuePlaceholder +=  ("F"+'{0:d3}' -f $X+++".COLUMN_NAME = '$LFField' ")
}

# Combine select from join and where into single SQL query
$SQLSelect = $SQLSelect + ($SQLFieldPlaceholder -join ", $OFS")
$SQLFrom = $SQLFrom + ($SQLTablePlaceholder -join ", $OFS")
$SQLJoins = $SQLJoins + (($SQLJoinsPlaceholder | Select -Skip 1) -join "AND $OFS")
$SQLWhere = $SQLWhere + ($SQLValuePlaceholder -join "AND $OFS")
$QUERY = $SQLSelect + $OFS + $SQLFrom + $OFS + $SQLJoins + $OFS + $SQLWhere

# Store the results
$PotentialTables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $QUERY -QueryTimeout 65524

# Ensure tables and fields match up

# Generate the update query

