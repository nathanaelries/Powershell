Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = [System.Windows.Forms.OpenFileDialog]::new()
$FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop') 
$FileBrowser.Filter = 'Powershell Scripts (*.ps1)|*.ps1'
$null = $FileBrowser.ShowDialog()
$script = $FileBrowser.FileName

$file = "C:\Users\nathanael.ries\Desktop\dsi.local.pfx"
$MyCertFromPfx = Get-PfxCertificate -FilePath $file

Set-AuthenticodeSignature -PSPath $script -Certificate $MyCertFromPfx
