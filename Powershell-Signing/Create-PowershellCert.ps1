Clear-Host

# Define certificate name
$Certname = Read-Host “Enter Certificate Name”

# Define expiration
$YearsToExpire = Read-Host “How many years should this certificate be valid”
Write-Host "Creating Certifcate $Certname" -ForegroundColor Green

# Create certificate
$Cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $Certname -Type CodeSigningCert -NotAfter (Get-Date).AddYears($YearsToExpire)
Write-Host "Exporting Certificate $Certname to $env:USERPROFILE\Desktop\$Certname.pfx" -ForegroundColor Green

# Set password to export certificate
$PWMatch = $false
while(!$PWMatch -or $pwd1.Password.Length -lt 16){
Clear-Host
$pwd1 = Get-Credential -Message "Create New Password:" -UserName $Certname 
$pwd2 = Get-Credential -Message "Re-enter New Password:" -UserName $Certname

if ($pwd1.GetNetworkCredential().password -ceq $pwd2.GetNetworkCredential().password) {
$PWMatch = $true 
} else {
write-warning "Passwords do not match!"
$PWMatch = $false
}
if ($pwd1.Password.Length -lt 16) {
Write-Warning "Password must be at least 16 characters long"
$herestr = @"

STEP#1 | Create a memorable password
    -- random word lists are longer, harder to crack, and easier to remember than passwords like: "(0mpu+3r!"

STEP#2 | Securing the password
    -- If you must write the password down, SAVE IT IN A SECURE VAULT!
    -- Passwords are like toothbrushes. Do not share them. Change them every 90 days. Don't forget them.

STEP#3 | Remembering the password
    -- Force yourself to type the password in manually until you feel confident you have memorised it!
"@
Write-Host $herestr;pause
}
}

$pw = ConvertTo-SecureString $pwd1.GetNetworkCredential().password -Force -AsPlainText

$pwd1 = $null
$pwd2 = $null

# Get thumbprint
$thumbprint = $Cert.Thumbprint

# Export certificate
Export-PfxCertificate -cert "cert:\localMachine\my\$thumbprint" -FilePath "$env:USERPROFILE\Desktop\$Certname.pfx" -Password $pw

$pw = $null
ii  "$env:USERPROFILE\Desktop\"
