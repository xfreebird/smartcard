param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$SignTool)
$ErrorActionPreference = 'Stop'
if (!$env:WINDOWS_MSI_CERTIFICATE_PFX_BASE64) { throw 'Missing standalone MSI signing certificate' }
$temp = Join-Path ([IO.Path]::GetTempPath()) ("esemnbun-msi-" + [guid]::NewGuid() + '.pfx')
$certificate = $null
try {
    [IO.File]::WriteAllBytes($temp, [Convert]::FromBase64String($env:WINDOWS_MSI_CERTIFICATE_PFX_BASE64))
    $password = ConvertTo-SecureString $env:WINDOWS_MSI_CERTIFICATE_PASSWORD -AsPlainText -Force
    $certificate = Import-PfxCertificate -FilePath $temp -Password $password -CertStoreLocation Cert:\CurrentUser\My
    if (!$certificate.HasPrivateKey -or $certificate.NotAfter -le (Get-Date)) { throw 'Invalid or expired MSI signing certificate' }
    & $SignTool sign /sha1 $certificate.Thumbprint /fd SHA256 /d eSemnBun $Path
    if ($LASTEXITCODE -ne 0) { throw 'Standalone MSI signing failed' }
    $signature = Get-AuthenticodeSignature $Path
    if ($signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint -or $signature.Status -eq 'HashMismatch') {
        throw 'MSI signature verification failed'
    }
    Export-Certificate -Cert $certificate -FilePath (Join-Path (Split-Path $Path) 'eSemnBun-self-signed.cer') -Force | Out-Null
    Write-Host "MSI signed with $($certificate.Thumbprint). Certificate is self-signed; manual trust is required."
}
finally {
    Remove-Item $temp -ErrorAction SilentlyContinue
    if ($certificate) { Remove-Item "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -ErrorAction SilentlyContinue }
}
