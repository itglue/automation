function Get-CloudflareITGlueMatchingTable {
    $ZoneMatchMatrix = @()
    $AllZones = New-CloudflareWebRequest -Endpoint 'zones'
    $Progress = 0
    
    foreach ($Zone in $AllZones.result) {
        Write-Progress -Activity 'CloudflareAPI' -Status 'Creating Matching Table' -CurrentOperation $Zone.name -PercentComplete ($Progress / ($AllZones.result | Measure-Object | ForEach-Object count) * 100)
        $ZoneRecords = New-CloudflareWebRequest -Endpoint "zones/$($Zone.id)/dns_records"
        $ITGlueClientUIDRecord = $null

        foreach ($Record in $ZoneRecords.result) {
            if ($Record.name -eq "itglueclientuid.$($Record.zone_name)" -and $Record.content) {
                $ITGlueClientUIDRecord = $Record.content
            }
        }
        $Row = [ordered]@{
            ZoneId          = $Zone.id
            ZoneName        = $Zone.name
            ITGlueClientUID = $ITGlueClientUIDRecord
        }
        $ZoneMatchMatrix += New-Object psobject -Property $Row
        $Progress++
    }

    if($ZoneMatchMatrix){
        Write-Progress -Activity 'CloudflareAPI' -Status 'Complete' -PercentComplete 100
        try {
            $ZoneMatchMatrix | Sort-Object ZoneName | Export-Csv 'ITGlueCloudflareMatchingTable.csv' -NoTypeInformation
            Invoke-Item 'ITGlueCloudflareMatchingTable.csv'
        }
        catch {
            Write-Warning 'Unable to create ITGlueCloudflareMatchingTable.csv in current directory'
        }
    }
}
