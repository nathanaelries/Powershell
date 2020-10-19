function Sign-PowershellCertGui{
<#
    .SYNOPSIS
        Sign-PowershellCertGui is a powershell function to assist in signing ps1 files.

    .DESCRIPTION
        Sign-PowershellCertGui is a powershell function to assist in signing ps1 files.
        First, browse to and open the powershell script, then, browse and open the pfx file.

#>

    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = [System.Windows.Forms.OpenFileDialog]::new()
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    $FileBrowser.Filter = 'Powershell Scripts (*.ps1)|*.ps1'
    $null = $FileBrowser.ShowDialog()
    $script = $FileBrowser.FileName

    $FileBrowser = [System.Windows.Forms.OpenFileDialog]::new()
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    $FileBrowser.Filter = 'Personal Information Exchange Files (*.pfx)|*.pfx'
    $null = $FileBrowser.ShowDialog()
    $file = $FileBrowser.FileName
    $MyCertFromPfx = Get-PfxCertificate -FilePath $file

    Set-AuthenticodeSignature -PSPath $script -Certificate $MyCertFromPfx
}
