function Add-CloudflareITGlueAPIAuth {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {   
        Write-Host 'Add/removing API Auth require admin access' -ForegroundColor Yellow
    }
    else {
        [pscredential]$CloudflareCredentials = $Host.UI.PromptForCredential('Cloudflare API Authentication', "User name:  Cloudflare Email`r`nPassword:    Cloudflare API Key", '', '')
        [pscredential]$ITGCredentials = $Host.UI.PromptForCredential('ITGlue API Authentication', 'Password:    ITGlue API Key', 'ITGlue', '')
        $Global:CloudflareAPIEmail = $CloudflareCredentials.username
        $Global:CloudflareAPIKey = $CloudflareCredentials.Password
        $Global:ITGlueAPIKey = $ITGCredentials.Password
        
        if (!$CloudflareAPIEmail -or !$CloudflareAPIKey -or !$ITGlueAPIKey) {
            Write-Host 'Cancelled' -ForegroundColor Yellow
            break
        }
        if ($CloudflareAPIEmail -notmatch "\A[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z") {
            Write-Host 'Invalid email address format' -ForegroundColor Yellow
            break
        }
        if (!$CloudflareCredentials.GetNetworkCredential().Password -or !$ITGCredentials.GetNetworkCredential().Password) {
            Write-Warning 'API key(s) not entered'
            break
        }
        $Credentials = @{
            CloudflareEmail  = $CloudflareAPIEmail
            CloudflareAPIKey = ($CloudflareAPIKey | ConvertFrom-SecureString)
            ITGlueAPIKey     = ($ITGlueAPIKey | ConvertFrom-SecureString)
        }
        $Auth = @()
        $Auth += [pscustomobject]$Credentials
        $ModuleBase = Get-Module CloudflareITGlue | ForEach-Object ModuleBase
        
        $Auth | Export-Csv "$ModuleBase\$env:username.auth" -NoTypeInformation -Force
    }
}

function Get-CloudflareITGlueAPIAuth {
    if (Test-Path "$ModuleBase\$env:username.auth") {
        Write-Host 'Auth file detected' -ForegroundColor Green
        $Auth = Import-Csv "$ModuleBase\$env:username.auth"
        
        try {
            $cfkey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($Auth.CloudflareAPIKey | ConvertTo-SecureString)))
            $itgkey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($Auth.ITGlueAPIKey | ConvertTo-SecureString)))
            $cfkeyhalf = [int]($cfkey | Measure-Object -Character | ForEach-Object Characters) / 2
            $itgkeyhalf = [int]($itgkey | Measure-Object -Character | ForEach-Object Characters) / 2
            Write-Host "Cloudflare Email: $($Auth.CloudflareEmail)"
            Write-Host "Cloudflare API Key: $($cfkey.Substring(0,$cfkeyhalf))********************" -ErrorAction Ignore
            Write-Host "ITGlue API Key: $($itgkey.Substring(0,$itgkeyhalf))********************`n" -ErrorAction Ignore
            $cfkey = $null
            $itgkey = $null
        }
        catch {
            Write-Warning 'Invalid format or unable to decrypt'
            Write-Warning 'Run Add-CloudflareITGlueAPIAuth to re-add auth info for the current account'
            $cfkey = $null
            $itgkey = $null
        }
    }
    else {
        Write-Host "No auth detected for $env:username" -ForegroundColor Yellow
    }
}

function Remove-CloudflareITGlueAPIAuth {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {   
        Write-Host 'Add/removing API Auth require admin access' -ForegroundColor Yellow
    }
    else {
        if (Test-Path "$ModuleBase\$env:username.auth") {
            Remove-Item "$ModuleBase\$env:username.auth" -Force
        }
        else {
            Write-Host 'Not added' -ForegroundColor Yellow
        }
    }
}
