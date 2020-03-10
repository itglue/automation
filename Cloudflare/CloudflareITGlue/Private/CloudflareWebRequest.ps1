function New-CloudflareWebRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Endpoint,
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')][string]$Method = 'GET',
        [string]$Body = $null,
        [int]$ResultsPerPage = 50,
        [int]$PageNumber = 1
    )
    
    if ($CloudflareAPIKey) {
        try {
            $APIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CloudflareAPIKey))
        }
        catch {
            Write-Warning 'Unable to decrypt auth info, run Add-CloudflareITGlueAPIAuth to re-add'
            if ($CFITGLog) {
                "[CF Request]$(Get-Date -Format G):  Unable to decrypt auth info, run Add-CloudflareITGlueAPIAuth to re-add" | Out-File $CFITGLog -Append
            }
            break
        }
    }
    else {
        Write-Warning 'Run Add-CloudflareITGlueAPIAuth to add authorization info'
        if ($CFITGLog) {
            "[CF Request]$(Get-Date -Format G):  Run Add-CloudflareITGlueAPIAuth to add authorization info" | Out-File $CFITGLog -Append
        }
        break
    }

    $RequestParams = @{
        Uri     = 'https://api.cloudflare.com/client/v4/' + $Endpoint + "?per_page=$ResultsPerPage&page=$PageNumber"
        Method  = $Method
        Headers = @{
            'X-Auth-Key'   = $APIKey
            'X-Auth-Email' = $CloudflareAPIEmail
            'Content-Type' = 'application/json'
        }
    }
    if ($Body) { $RequestParams.Body = $Body }
    
    try {
        $Request = Invoke-RestMethod @RequestParams
        Start-Sleep -Milliseconds 325
        # RateLimit: 1200/5 min
                
        if ($PageNumber -lt $Request.result_info.total_pages) {
            $PageNumber++
            New-CloudflareWebRequest -Endpoint $Endpoint -ResultsPerPage $ResultsPerPage -PageNumber $PageNumber
        }
        $APIKey = $null
        $RequestParams = $null
        return $Request
    }
    catch {
        Write-Warning "Something went wrong with Cloudflare request:`n$_"
        if ($CFITGLog) {
            "[CF Request: $Endpoint]$(Get-Date -Format G):  $_" | Out-File $CFITGLog -Append
        }
        
        $APIKey = $null
        $RequestParams = $null
    }
}
