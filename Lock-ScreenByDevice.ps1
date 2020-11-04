  Clear-Host

$scroll = "/-\|/-\|"
$idx = 0
$origpos = $host.UI.RawUI.CursorPosition
$origpos.Y += 1

Write-Warning "Please remove device before proceeding"

pause

start-sleep -seconds 5

$devices1 = Get-PnpDevice

Write-Warning "Please connect device before proceeding"

pause

start-sleep -seconds 5

clear-host

$devices2 = Get-PnpDevice

$devicelist = Compare-Object -ReferenceObject $devices1 -DifferenceObject $devices2 -Property status,FriendlyName,InstanceID

$List = @()
($devicelist.InstanceID -creplace '^[^\\]*\\', '').ForEach({
    $_ = $_.Substring(0, $_.IndexOf('\'))
    $list += $_ -split '&' 
})

$VIDlist = $list | Where {$_ -like 'VID_*'}
$V_ID = $VIDlist | Group-Object | Sort-Object Count -descending | Select-Object -First 1 -ExpandProperty Name

$PIDlist = $list | Where {$_ -like 'PID_*'}
$P_ID = $PIDlist | Group-Object | Sort-Object Count -descending | Select-Object -First 1 -ExpandProperty Name

clear-host

Write-Warning "Computer will lock itself if the following device is removed..."
Get-PnpDevice | where {$_.InstanceID -like "*$V_ID&$P_ID*" -and $_.Status -eq 'OK'}
pause
clear-host

function WorkstationUnlocked(){
$currentuser = gwmi -Class win32_computersystem | select -ExpandProperty username
$process = get-process logonui -ea silentlycontinue
if($currentuser -and $process){return $false}else{return $true}
}


while($true){
$detect = Get-PnpDevice | where {$_.InstanceID -like "*$V_ID&$P_ID*"} 
$host.UI.RawUI.CursorPosition = $origpos

    Write-Host $scroll[$idx] -NoNewline
	$idx++
	if ($idx -ge $scroll.Length)
	{
		$idx = 0
	}
	Start-Sleep -Milliseconds 100
if($detect.status -contains 'OK'){

}
elseif (WorkstationUnlocked){rundll32.exe user32.dll,LockWorkStation}
}
