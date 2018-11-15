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
            Write-Warning 'New-CloudflareWebRequest:  Unable to decrypt auth info'
            Write-Warning 'Run Add-CloudflareITGlueAPIAuth to re-add'
            break
        }
    }
    else {
        Write-Warning 'Run Add-CloudflareITGlueAPIAuth to add authorization info'
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
    if ($Body) {$RequestParams.Body = $Body}
    
    try {
        Start-Sleep -Milliseconds 275
        $Request = Invoke-RestMethod @RequestParams
        Start-Sleep -Milliseconds 275
        #RateLimit = 1200 requests/5 min but still getting gateway timeouts @ 300ms+
                
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
        $APIKey = $null
        $RequestParams = $null
    }
}
