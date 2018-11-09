function New-ITGlueWebRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Endpoint,
        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE')][string]$Method = 'GET',
        [string]$Body = $null,
        [int]$ResultsPerPage = 50,
        [int]$PageNumber = 1
    )
    
    if ($ITGlueAPIKey) {
        try {
            $APIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ITGlueAPIKey))
        }
        catch {
            Write-Warning 'New-ITGlueWebRequest:  Unable to decrypt auth info'
            Write-Warning 'Run Add-CloudflareITGlueAPIAuth to re-add'
            break
        }
    }
    else {
        Write-Warning 'Run Add-CloudflareITGlueAPIAuth to add authorization info'
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
    if ($Body) {$RequestParams.Body = $Body}

    try {
        $Request = Invoke-RestMethod @RequestParams

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
        $APIKey = $null
        $RequestParams = $null
    }
}
