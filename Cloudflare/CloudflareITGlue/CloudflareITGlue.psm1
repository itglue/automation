$ModuleBase = Get-Module CloudflareITGlue -ListAvailable | ForEach-Object ModuleBase

if (Test-Path "$ModuleBase\$env:username.auth") {
    Write-Host "CloudflareITGlue: Auth detected for $env:username" -ForegroundColor Green
    $Auth = Import-Csv "$ModuleBase\$env:username.auth"
    
    Set-Variable -Name CloudflareAPIEmail -Scope global -Value $Auth.CloudflareEmail
    Set-Variable -Name CloudflareAPIKey -Scope global -Value ($Auth.CloudflareAPIKey | ConvertTo-SecureString)
    Set-Variable -Name ITGlueAPIKey -Scope global -Value ($Auth.ITGlueAPIKey | ConvertTo-SecureString)
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
