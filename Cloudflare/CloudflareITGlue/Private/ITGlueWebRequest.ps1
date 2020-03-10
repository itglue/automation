function New-ITGlueWebRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Endpoint,
        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE')][string]$Method = 'GET',
        [string]$Body = $null,
        [int]$ResultsPerPage = 50,
        [int]$PageNumber = 1,
        [string]$Params = $null
    )
    
    if ($ITGlueAPIKey) {
        try {
            $APIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ITGlueAPIKey))
        }
        catch {
            Write-Warning 'Unable to decrypt auth info, run Add-CloudflareITGlueAPIAuth to re-add'
            if ($CFITGLog) {
                "[ITG Request]$(Get-Date -Format G):  Unable to decrypt auth info, run Add-CloudflareITGlueAPIAuth to re-add" | Out-File $CFITGLog -Append
            }
            break
        }
    }
    else {
        Write-Warning 'Run Add-CloudflareITGlueAPIAuth to add authorization info'
        if ($CFITGLog) {
            "[ITG Request]$(Get-Date -Format G):  Run Add-CloudflareITGlueAPIAuth to add authorization info" | Out-File $CFITGLog -Append
        }
        break
    }
   
    $RequestParams = @{
        Uri     = 'https://api.itglue.com/' + $Endpoint + "?page[size]=$ResultsPerPage&page[number]=$PageNumber"
        Method  = $Method
        Headers = @{
            'x-api-key'    = $APIKey
            'Content-Type' = 'application/vnd.api+json'
        }
    }
    if ($Params) { $RequestParams.Uri += "&$Params" }
    if ($Body) { $RequestParams.Body = $Body }

    try {
        $Request = Invoke-RestMethod @RequestParams
        # RateLimit: 10k/day

        if ($PageNumber -lt $Request.meta.'total-pages') {
            $PageNumber++
            New-ITGlueWebRequest -Endpoint $Endpoint -Body $Body -ResultsPerPage $ResultsPerPage -PageNumber $PageNumber
        }
        $APIKey = $null
        $RequestParams = $null
        return $Request
    }
    catch {
        Write-Warning "Something went wrong with ITGlue request:`n$_"
        if ($CFITGLog) {
            "[ITG Request: $Endpoint]$(Get-Date -Format G):  $_" | Out-File $CFITGLog -Append
        }

        $APIKey = $null
        $RequestParams = $null
    }
}
