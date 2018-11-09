function Sync-CloudflareITGlueFlexibleAssets {
    
    $Progress = 0
    $ZoneDataArray = Get-CloudflareZoneDataArray
    $FlexAssetTypeId = New-ITGlueWebRequest -Endpoint 'flexible_asset_types' -Method 'GET' | ForEach-Object data | Where-Object {$_.attributes.name -eq 'Cloudflare DNS'} | ForEach-Object id

    foreach ($ZoneData in $ZoneDataArray) {
        Write-Progress -Activity 'ITGlueAPI' -Status 'Syncing Flexible Assets' -CurrentOperation $ZoneData.name -PercentComplete ($Progress / ($ZoneDataArray | Measure-Object | foreach-object count) * 100) -Id 2

        $TempFile = New-TemporaryFile
        $ZoneData.ZoneFileData | Out-file $TempFile -Force -Encoding utf8
        $Base64ZoneFile = ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($TempFile)))
        Remove-Item $TempFile -Force
        $RecordsHtml = 
            '<div>
                <table id="RecordTable" style="width:100%">
                    <thead>
                        <th>Type</th>
                        <th>Name</th>
                        <th>Value</th>
                        <th>Priority</th>
                        <th>TTL</th>
                        <th>Proxied</th>
                        <th>Modified</th>
                    </thead>
                    <tbody>' +
                    $(foreach ($Record in $ZoneData.dnsrecords) {
                        "<tr>
                            <td>$($Record.type)</td>
                            <td>$($Record.name)</td>
                            <td>$($Record.value)</td>
                            <td>$($Record.priority)</td>
                            <td>$($Record.ttl)</td>
                            <td>$($Record.proxied)</td>
                            <td>$($Record.modified)</td>
                        </tr>"
                    }) +
                    '</tbody>
                </table>
            </div>'

        $Body = @{
            data = @{
                'type' = 'flexible-assets'
                'attributes' = @{
                    'organization-id' = $($ZoneData.ITGlueClientID)
                    'flexible-asset-type-id' = $FlexAssetTypeId
                    'traits' = @{
                        'name' = $ZoneData.Name
                        'last-sync' = $ZoneData.SyncDate
                        'nameservers' = $ZoneData.CfNameServers -join '<br>'
                        'status' = $ZoneData.Status
                        'zone-file' = @{
                            'content' = $Base64ZoneFile
                            'file_name' = "$($ZoneData.Name).txt"
                        }
                        'dns-records' = $RecordsHtml
                    }
                }
            }
        }

        $Body = $Body | ConvertTo-Json -Depth 4
        $FlexAssets = New-ITGlueWebRequest -Endpoint "flexible_assets?filter[flexible_asset_type_id]=$FlexAssetTypeId&filter[organization_id]=$($ZoneData.ITGlueClientID)" -Method 'GET' | ForEach-Object data
        $PatchId = $null
        foreach ($FlexAsset in $FlexAssets) {
            if ($FlexAsset.attributes.traits.name -eq $ZoneData.name) {
                $PatchId = $FlexAsset.id
            }
        }
        
        if ($PatchId) {
            New-ITGlueWebRequest -Endpoint "flexible_assets/$PatchId" -Method 'PATCH' -Body $Body
        }
        else {
            New-ITGlueWebRequest -Endpoint 'flexible_assets' -Method 'POST' -Body $Body    
        }
        $Progress++
    }
    Write-Progress -Activity 'ITGlueAPI' -Status 'Syncing Flexible Assets' -PercentComplete 100 -Id 2
}
