Function Get-FileName()
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.filter = "PFX (*.pfx)| *.pfx"
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.FileName
}

$myPfx = Get-FileName

$MyStrongPassword = (Get-Credential -UserName "no username required" -Message ("Password to " + $myPfx | Split-Path -Leaf )).password

#How to import your Self signed PFX
#Personal
Import-PfxCertificate -FilePath $myPfx -CertStoreLocation "cert:\LocalMachine\My" -Password $MyStrongPassword 
#TrustedPublisher
Import-PfxCertificate -FilePath $myPfx -CertStoreLocation "cert:\LocalMachine\Root" -Password $MyStrongPassword 
#Root
Import-PfxCertificate -FilePath $myPfx -CertStoreLocation "cert:\LocalMachine\TrustedPublisher" -Password $MyStrongPassword
