Clear-Host


$ScriptTitle = "Whatever"
$InternalFileServerPath = "\\server\path"
$InternalFileServerName = "server.internal.domain"
$DriveName = "DriveName"


# Assemblies needed for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework


# Creates popup messages
function Out-Popup($text,$title,$buttonsArr) {
    $scriptblock = [scriptblock]::Create(("[System.Windows.MessageBox]::Show(""$text"",""$title"","""+($buttonsArr -join'","')+""",'Error')"))
    Invoke-Command -ScriptBlock $scriptblock
}


# Check that an internal file server is accessible

try{Resolve-DnsName -Name $InternalFileServerName -ErrorAction Stop}catch{    Out-Popup -text "Failed to connect to internal server. Are you connected to the VPN?" -title $ScriptTitle -buttonsArr @("OK")
    return $false
}


# Function to validate credentials against AD controller
function Test-Cred {


    [CmdletBinding()]
    [OutputType([String])]


    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias(
            'PSCredential'
        )]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials
    )
    $Domain = $null
    $Root = $null
    $Username = $null
    $Password = $null


    If($Credentials -eq $null)
    {
        Try
        {
            $Credentials = Get-Credential "domain\$env:username" -ErrorAction Stop
        }
        Catch
        {
            $ErrorMsg = $_.Exception.Message
            Write-Warning "Failed to validate credentials: $ErrorMsg "
            return $false
        }
    }


    # Checking module
    Try
    {
        # Split username and password
        $Username = $credentials.username
        $Password = $credentials.GetNetworkCredential().password


        # Get Domain
        $Root = "LDAP://" + ([ADSI]'').distinguishedName
        $Domain = New-Object System.DirectoryServices.DirectoryEntry($Root,$UserName,$Password)
    }
    Catch
    {
        $_.Exception.Message
        Continue
    }


    If(!$domain)
    {
        Write-Warning "Something went wrong"
    }
    Else
    {
        If ($domain.name -ne $null)
        {
            return "Authenticated"
        }
        Else
        {
            return "Not authenticated"
        }
    }
}


# User supplied $cred
$cred = Get-Credential -Message "Provide Credentials. Include domain in the username field. (example: '$env:USERDOMAIN\$env:USERNAME')" -UserName "$env:USERDOMAIN\$env:USERNAME"


# Validate the user supplied $cred
$CredCheck = $cred | Test-Cred
If($CredCheck -ne "Authenticated")
{
    Out-popup -text "Failed to validate credentials." -title 'Export-Deletion' -buttonsArr @("OK")
    return $false
}


# Map a shared drive
$i=0;while ((Test-Path $InternalFileServerPath) -eq $false -and $i -le 3){
    try{New-PSDrive -name $DriveName -Root $InternalFileServerPath -PSProvider FileSystem -Credential $cred -ErrorAction SilentlyContinue }catch{}
    start-sleep -Seconds 1; $i++
}


# If the drive can't map, tell the user to make sure the VPN is connected
if ((Test-Path $InternalFileServerPath) -eq $false){
    Out-Popup -text "Failed to connect to '$InternalFileServerPath' Are you connected to the VPN? Is the '$InternalFileServerPath' accessible?" -title "Export-Deletion" -buttonsArr @("OK")
    return $false
}
