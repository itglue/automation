$ModuleBase = Get-Module CloudflareITGlue -ListAvailable | ForEach-Object ModuleBase

if (Test-Path "$ModuleBase\$env:username.auth") {
    Write-Host "CloudflareITGlue: Auth detected for $env:username" -ForegroundColor Green
    $Auth = Import-Csv "$ModuleBase\$env:username.auth"
    $Global:CloudflareAPIEmail = $Auth.CloudflareEmail
    $Global:CloudflareAPIKey = ($Auth.CloudflareAPIKey | ConvertTo-SecureString)
    $Global:ITGlueAPIKey = ($Auth.ITGlueAPIKey | ConvertTo-SecureString)
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
