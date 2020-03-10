function Get-CloudflareZoneData {
    param(
        [Parameter(Mandatory = $true)][string]$ZoneId,
        [Parameter(Mandatory = $true)][pscustomobject]$ITGMatch
    )
    
    $DateUTC = (Get-Date).ToUniversalTime().ToString('yyyy-M-d')
    $AccountId = New-CloudflareWebRequest -Endpoint 'accounts' | ForEach-Object result | ForEach-Object id
    $ZoneInfo = New-CloudflareWebRequest -Endpoint "zones/$ZoneId"
    $ZoneRecords = New-CloudflareWebRequest -Endpoint "zones/$ZoneId/dns_records"
    if ($ZoneRecords.result_info.count -eq 0) {
        Write-Host "$($ZoneInfo.result.name): Empty Zone Detected" -ForegroundColor Yellow
        if ($CFITGLog) {
            "[CF]$(Get-Date -Format G):  Empty Zone Detected - $($ZoneInfo.result.name)" | Out-File $CFITGLog -Append
        }
        break
    }
    $ZoneFileData = New-CloudflareWebRequest -Endpoint "zones/$ZoneId/dns_records/export"
    $ZoneFileData = $ZoneFileData.Replace(
        ';; SOA Record',
        "`$ORIGIN $($ZoneInfo.result.name).`n`n;; SOA Record"
    )
    $ZoneFileData = $ZoneFileData.Replace(
        "SOA`t$($ZoneInfo.result.name). root.$($ZoneInfo.result.name).",
        "SOA`t$($ZoneInfo.result.name_servers[0]). $((($CloudflareAPIEmail -split '@')[0]).Replace('.','\.') + '.'+ ($CloudflareAPIEmail -split '@')[1])."
    )
    $ZoneFileData = $ZoneFileData.Replace(
        ';; A Records',
        ";; NS Records`n$($ZoneInfo.result.name).	1	IN	NS	$($ZoneInfo.result.name_servers[0]).`n$($ZoneInfo.result.name).	1	IN	NS	$($ZoneInfo.result.name_servers[1]).`n`n;; A Records"
    )
    $ZoneFileData = $ZoneFileData.Replace(
        ';;   -- update the SOA record with the correct authoritative name server',
        ";;   -- update the SOA record with the correct authoritative name server`n;;   ** CloudflareITGlue Module: Updated $($DateUTC)"
    )
    $ZoneFileData = $ZoneFileData.Replace(
        ';;   -- update the SOA record with the contact e-mail address information',
        ";;   -- update the SOA record with the contact e-mail address information`n;;   ** CloudflareITGlue Module: Updated $($DateUTC)"
    )
    $ZoneFileData = $ZoneFileData.Replace(
        ';;   -- update the NS record(s) with the authoritative name servers for this domain.',
        ";;   -- update the NS record(s) with the authoritative name servers for this domain.`n;;   ** CloudflareITGlue Module: Updated $($DateUTC)`n;;   ** CloudflareITGlue Module: Added `$ORIGIN directive"
    )
    $RecordsHtml = 
    '<div>
        <p><a class="btn btn-sm btn-default" href="https://dash.cloudflare.com/' + $AccountId + "/$($ZoneInfo.result.name)" + '/dns" rel="nofollow" style="display: inline" title="Cloudflare">
        <i class="fa fa-fw fa-external-link"></i><span>Open in Cloudflare</span></a></p>
        
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
                $(foreach ($Record in $ZoneRecords.result) {
                    "<tr>
                        <td>$($Record.type)</td>
                        <td>$($Record.name)</td>
                        <td>$($Record.content)</td>
                        <td>$($Record.priority)</td>
                        <td>$(if ($Record.ttl -eq 1){'Auto'}else{$Record.ttl})</td>
                        <td>$($Record.proxied)</td>
                        <td>$(($Record.modified_on.Replace('T', ' ') -split '\.')[0])</td>
                    </tr>"
                }) +
            '</tbody>
        </table>
    </div>'
    
    $ZoneData = [ordered]@{
        Name          = $ZoneInfo.result.name
        SyncDate      = $DateUTC
        CfNameServers = $ZoneInfo.result.name_servers
        Status        = $ZoneInfo.result.status
        ZoneFileData  = $ZoneFileData
        RecordsHtml   = $RecordsHtml
        ITGOrg        = $Match.OrgMatchId
        DomainTracker = $Match.DomainTrackerId
    }
    $ZoneData
}

function Get-CloudflareZoneDataArray {
    $Progress = 0
    Write-Progress -Activity 'CloudflareAPI' -Status 'Getting Zone Data' -PercentComplete 0 -Id 1
    $ZoneDataArray = @()
    $AllZones = New-CloudflareWebRequest -Endpoint 'zones'
    [pscustomobject]$ITGDomains = New-ITGlueWebRequest -Endpoint 'domains' | ForEach-Object data
    
    foreach ($Zone in $AllZones.result) {
        Write-Progress -Activity 'CloudflareAPI' -Status 'Getting Zone Data' -CurrentOperation $Zone.name -PercentComplete ($Progress / ($AllZones.result | Measure-Object | ForEach-Object count) * 100) -Id 1
        
        $ITGMatches = @()
        foreach ($ITGDomain in $ITGDomains) {
            if ($Zone.name.ToLower() -eq $ITGDomain.attributes.name.ToLower()) {
                $Match = @{
                    OrgMatchId      = $ITGDomain.attributes.'organization-id'
                    DomainTrackerId = $ITGDomain.id
                }
                $ITGMatches += [pscustomobject]$Match
            }
        }
        if ($ITGMatches) {
            foreach ($Match in $ITGMatches) {
                $ZoneData = Get-CloudflareZoneData -ZoneId $Zone.id -ITGMatch $Match
                if ($ZoneData) {
                    $ZoneDataArray += [pscustomobject]$ZoneData
                }
            }
        }
        else {
            Write-Host "$($Zone.name): Add to domain tracker" -ForegroundColor Yellow
            if ($CFITGLog) {
                "[CFITG]$(Get-Date -Format G):  $($Zone.name) - Add to ITG domain tracker" | Out-File $CFITGLog -Append
            }
        }
        $Progress++
    }
    Write-Progress -Activity 'CloudflareAPI' -Status 'Complete' -PercentComplete 100 -Id 1
    $ZoneDataArray
}
