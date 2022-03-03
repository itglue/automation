function Sync-CloudflareITGlueFlexibleAssets {
    param(
        [string]$FlexAssetType = 'Cloudflare DNS',
        [string]$Log
    )
    $Progress = 0

    if ($Log) {
        if (Test-Path $Log) {
            $Global:CFITGLog = $Log
        }
        else {
            New-Item -ItemType File -Path $Log -ErrorAction Ignore | Out-Null
            if (Test-Path $Log) {
                $Global:CFITGLog = $Log
            }
            else {
                Write-Warning "Unable to create log file: $Log - Invalid path or access denied"
                return
            }
        }
    }
    
    $ZoneDataArray = Get-CloudflareZoneDataArray
    $FlexAssetTypeId = New-ITGlueWebRequest -Endpoint 'flexible_asset_types' -Method 'GET' | ForEach-Object data | Where-Object { $_.attributes.name -eq $FlexAssetType } | ForEach-Object id
    if (!$FlexAssetTypeId) {
        New-CloudflareITGlueFlexAssetType -Name $FlexAssetType | Out-Null
        $FlexAssetTypeId = New-ITGlueWebRequest -Endpoint 'flexible_asset_types' -Method 'GET' | ForEach-Object data | Where-Object { $_.attributes.name -eq $FlexAssetType } | ForEach-Object id
    }

    foreach ($ZoneData in $ZoneDataArray) {
        Write-Progress -Activity 'ITGlueAPI' -Status 'Syncing Flexible Assets' -CurrentOperation $ZoneData.name -PercentComplete ($Progress / ($ZoneDataArray | Measure-Object | ForEach-Object count) * 100) -Id 2

        $TempFile = New-TemporaryFile
        $ZoneData.ZoneFileData | Out-file $TempFile -Force -Encoding ascii
        $Base64ZoneFile = ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($TempFile)))
        Remove-Item $TempFile -Force
        $Body = @{
            data = @{
                'type'       = 'flexible-assets'
                'attributes' = @{
                    'organization-id'        = $ZoneData.ITGOrg
                    'flexible-asset-type-id' = $FlexAssetTypeId
                    'traits'                 = @{
                        'name'        = $ZoneData.Name
                        'last-sync'   = $ZoneData.SyncDate
                        'nameservers' = $ZoneData.CfNameServers -join '<br>'
                        'status'      = $ZoneData.Status
                        'zone-file'   = @{
                            'content'   = $Base64ZoneFile
                            'file_name' = "$($ZoneData.Name)_$((Get-Date).ToUniversalTime() | Get-Date -Format "yyyy-MM-ddTHHmmssK").txt"
                        }
                        'dns-records' = $ZoneData.RecordsHtml
                    }
                }
            }
        }
        $Body = $Body | ConvertTo-Json -Depth 4
        $FlexAssets = New-ITGlueWebRequest -Endpoint "flexible_assets?filter[flexible_asset_type_id]=$FlexAssetTypeId&filter[organization_id]=$($ZoneData.ITGOrg)" -Method 'GET' | ForEach-Object data
        $PatchId = $null
        
        foreach ($FlexAsset in $FlexAssets) {
            if ($FlexAsset.attributes.traits.name -eq $ZoneData.name) {
                $PatchId = $FlexAsset.id
            }
        }
        if ($PatchId) {
            try {
                $FlexAssetId = New-ITGlueWebRequest -Endpoint "flexible_assets/$PatchId" -Method 'PATCH' -Body $Body
                if ($CFITGLog) {
                    "[ITG]$(Get-Date -Format G):  Updating $($ZoneData.Name)" | Out-File $CFITGLog -Append
                }
            }
            catch {
                Write-Warning "Something went wrong updating $($ZoneData.Name)`n$_"
                if ($CFITGLog) {
                    "[ITG]$(Get-Date -Format G):  Something went wrong updating $($ZoneData.Name)`n$_" | Out-File $CFITGLog -Append
                }
                continue
            }
        }
        else {
            try {
                $FlexAssetId = New-ITGlueWebRequest -Endpoint 'flexible_assets' -Method 'POST' -Body $Body
                if ($CFITGLog) {
                    "[ITG]$(Get-Date -Format G):  Creating $($ZoneData.Name)" | Out-File $CFITGLog -Append
                }
            }
            catch {
                Write-Warning "Something went wrong creating $($ZoneData.Name)`n$_"
                if ($CFITGLog) {
                    "[ITG]$(Get-Date -Format G):  Something went wrong creating $($ZoneData.Name)`n$_" | Out-File $CFITGLog -Append
                }
                continue
            }
        }
        $TagBody = @{
            data = @{
                type       = 'related_items'
                attributes = @{
                    'destination_id'   = $ZoneData.DomainTracker
                    'destination_type' = 'Domain'
                }
            }
        }
        $TagBody = $TagBody | ConvertTo-Json -Depth 4
        New-ITGlueWebRequest -Endpoint "flexible_assets/$($FlexAssetId.data.id)/relationships/related_items" -Method POST -Body $TagBody | Out-Null

        $Progress++
    }
    Write-Progress -Activity 'ITGlueAPI' -Status 'Syncing Flexible Assets' -PercentComplete 100 -Id 2
}
