function Get-CloudflareZoneData {
    param(
        [Parameter(Mandatory = $true)][string]$ZoneId
    )

    $ZoneRecords = New-CloudflareWebRequest -Endpoint "zones/$ZoneId/dns_records"
    $RecordArray = @()
    $ITGlueClientUIDRecord = $null
    
    foreach ($Record in $ZoneRecords.result) {
        $RecordEntry = [ordered]@{
            Type     = $Record.type
            Name     = $Record.name
            Value    = $Record.content
            Priority = $Record.priority
            TTL      = if ($Record.ttl -eq 1){'Auto'}else{$Record.ttl}
            Proxied  = $Record.proxied
            Modified = ($Record.modified_on.Replace('T', ' ') -split '\.')[0]
        }
        $RecordArray += New-Object PSObject -Property $RecordEntry
        
        if ($Record.name -eq "itglueclientuid.$($Record.zone_name)") {
            $ITGlueClientUIDRecord = $Record.content
        }
    }

    if ($ITGlueClientUIDRecord) {
        $ZoneInfo = New-CloudflareWebRequest -Endpoint "zones/$ZoneId"
        $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-M-d HH:mm:ss")
        $ZoneFileData = New-CloudflareWebRequest -Endpoint "zones/$ZoneId/dns_records/export"
        $ZoneFileData = $ZoneFileData.Replace(
            "@	3600	IN	SOA	$($ZoneInfo.result.name).	root.$($ZoneInfo.result.name).	(",
            "@	3600	IN	SOA	$($ZoneInfo.result.name_servers[0]). $((($CloudflareAPIEmail -split '@')[0]).Replace('.','\.') + '.'+ ($CloudflareAPIEmail -split '@')[1]). ("
        )
        $ZoneFileData = $ZoneFileData.Replace(
            ";; NS Records (YOU MUST CHANGE THIS)`n$($ZoneInfo.result.name).	1	IN	NS	" + 'REPLACE&ME$WITH^YOUR@NAMESERVER.',
            ";; NS Records`n$($ZoneInfo.result.name).	1	IN	NS	$($ZoneInfo.result.name_servers[0]).`n$($ZoneInfo.result.name).	1	IN	NS	$($ZoneInfo.result.name_servers[1])."
        )
        $ZoneFileData = $ZoneFileData.Replace(
            ';;   -- update the SOA record with the correct authoritative name server',
            ";;   -- update the SOA record with the correct authoritative name server`n;;   ** CloudflareITGlue Module: Updated $($Timestamp)"
        )
        $ZoneFileData = $ZoneFileData.Replace(
            ';;   -- update the SOA record with the contact e-mail address information',
            ";;   -- update the SOA record with the contact e-mail address information`n;;   ** CloudflareITGlue Module: Updated $($Timestamp)"
        )
        $ZoneFileData = $ZoneFileData.Replace(
            ';;   -- update the NS record(s) with the authoritative name servers for this domain.',
            ";;   -- update the NS record(s) with the authoritative name servers for this domain.`n;;   ** CloudflareITGlue Module: Updated $($Timestamp)"
        )
        $ZoneData = [ordered]@{
            Name           = $ZoneInfo.result.name
            ITGlueClientID = ($ITGlueClientUIDRecord -split '__')[1]
            SyncDate       = $Timestamp
            CfNameServers  = $ZoneInfo.result.name_servers
            Status         = $ZoneInfo.result.status
            ZoneFileData   = $ZoneFileData
            DNSRecords     = $RecordArray
        }
        $ZoneData
    }
}

function Get-CloudflareZoneDataArray {
    $ZoneDataArray = @()
    $AllZones = New-CloudflareWebRequest -Endpoint 'zones'
    $Progress = 0

    foreach ($Zone in $AllZones.result) {
        Write-Progress -Activity 'CloudflareAPI' -Status 'Getting Zone Data' -CurrentOperation $Zone.name -PercentComplete ($Progress / ($AllZones.result | Measure-Object | ForEach-Object count) * 100) -Id 1
        $ZoneData = Get-CloudflareZoneData -ZoneId $Zone.id
        if ($ZoneData) {
            $ZoneDataArray += New-Object psobject -Property $ZoneData
        }
        $Progress++
    }
    Write-Progress -Activity 'CloudflareAPI' -Status 'Complete' -PercentComplete 100 -Id 1
    $ZoneDataArray
}
