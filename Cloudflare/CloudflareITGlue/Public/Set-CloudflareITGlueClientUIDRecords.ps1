function Set-CloudflareITGlueClientUIDRecords {
    param(
        [Parameter(Mandatory = $true, Position = 0)]$MatchingTable
    )

    $MatchingTable = Import-Csv $MatchingTable
    $Progress = 0

    foreach ($Zone in $MatchingTable) {
        Write-Progress -Activity 'Cloudflare API' -Status 'Setting UID TXT Records' -CurrentOperation $Zone.ZoneName -PercentComplete ($Progress / ($MatchingTable | Measure-Object | ForEach-Object count) * 100)
        $ZoneRecords = New-CloudflareWebRequest -Endpoint "zones/$($Zone.ZoneId)/dns_records"
        $ITGlueClientUIDRecord = $ZoneRecords.result | Where-Object {$_.type -eq 'TXT' -and $_.name -like 'itglueclientuid.*'} | ForEach-Object content
        $ITGlueClientUIDRecordId = $ZoneRecords.result | Where-Object {$_.type -eq 'TXT' -and $_.name -like 'itglueclientuid.*'} | ForEach-Object id
        
        if ($ITGlueClientUIDRecord) {
            if (!$Zone.ITGlueClientUID) {
                Write-Host "$($Zone.ZoneName): itglueclientuid record exists but has been removed from matching table, deleting dns record." -ForegroundColor DarkCyan
                $Delete = New-CloudflareWebRequest -Endpoint "zones/$($Zone.ZoneId)/dns_records/$ITGlueClientUIDRecordId" -Method 'DELETE'
            }
            elseif ($Zone.ITGlueClientUID -and $ITGlueClientUIDRecord -ne $Zone.ITGlueClientUID) {
                Write-Host "$($Zone.ZoneName): itglueclientuid record exists but does not match, updating dns record." -ForegroundColor DarkCyan
                $data = '{"type":"TXT","name":"itglueclientuid","content":"' + $Zone.ITGlueClientUID + '"}'
                $Set = New-CloudflareWebRequest -Endpoint "zones/$($Zone.ZoneId)/dns_records/$ITGlueClientUIDRecordId" -Method 'PUT' -Body $Data
            }
            else {
                Write-Host "$($Zone.ZoneName): itglueclientuid record exists." -ForegroundColor DarkCyan
            }
        }
        elseif ($Zone.ITGlueClientUID) {
            Write-Host "$($Zone.ZoneName): itglueclientuid record not found, creating." -ForegroundColor DarkCyan
            $data = '{"type":"TXT","name":"itglueclientuid","content":"' + $Zone.ITGlueClientUID + '"}'
            $Create = New-CloudflareWebRequest -Endpoint "zones/$($Zone.ZoneId)/dns_records" -Method 'POST' -Body $Data
        }
        else {
            Write-Host "$($Zone.ZoneName): not matched" -ForegroundColor DarkCyan
        }
        $Progress++
    }
    Write-Progress -Activity 'Cloudflare API' -Status 'Setting UID TXT Records' -PercentComplete 100
}
