
# Initialize an array to store the results
$results = @()

$status = Invoke-Command -ScriptBlock {
    $scanInfo = Get-MpComputerStatus

    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        RealTimeProtectionEnabled = $scanInfo.RealTimeProtectionEnabled
        LastScanTime = $scanInfo.QuickScanStartTime
        LastUpdateTime = $scanInfo.AntivirusSignatureLastUpdated
        SignatureVersion = $scanInfo.AntivirusSignatureVersion
        }
}
   
$results += $status

$results | Export-Csv -Path "defender_status_$env:COMPUTERNAME.csv" -NoTypeInformation
