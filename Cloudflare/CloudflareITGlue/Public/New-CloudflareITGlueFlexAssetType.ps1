function New-CloudflareITGlueFlexAssetType {
    param(
        [string]$Name = 'Cloudflare DNS'
    )

    $Body = @{
        Data = @{
            type          = 'flexible_asset_types'
            attributes    = @{
                name         = $Name
                description  = 'DNS Zones from Cloudflare.'
                icon         = 'cloud'
                enabled      = $true
                show_in_menu = $false
            }
    
            relationships = @{
                flexible_asset_fields = @{
                    data = @(
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order         = 1
                                name          = 'Name'
                                kind          = 'Text'
                                hint          = 'Name of the DNS Zone'
                                required      = $true
                                show_in_list  = $true
                                use_for_title = $true
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 2
                                name         = 'Last Sync'
                                kind         = 'Text'
                                hint         = 'When zone last synced (UTC)'
                                required     = $true
                                show_in_list = $false
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 3
                                name         = 'Nameservers'
                                kind         = 'Textbox'
                                hint         = 'Cloudflare provided nameservers for this zone'
                                required     = $true
                                show_in_list = $false
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 4
                                name         = 'Status'
                                kind         = 'Text'
                                hint         = 'Status of the Cloudflare Zone'
                                required     = $false
                                show_in_list = $true
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 5
                                name         = 'Zone File'
                                kind         = 'Upload'
                                hint         = 'Exported zone file in BIND format. You can upload this to Cloudflare. UTF-8 Encoded, use notepad++ for better viewing.'
                                required     = $false
                                show_in_list = $false
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 6
                                name         = 'Domain Tracker'
                                kind         = 'Tag'
                                hint         = 'Tagged in Domain Tracker'
                                tag_type     = 'Domains'
                                required     = $false
                                show_in_list = $false
                            }
                        },
                        @{
                            type       = 'flexible_asset_fields'
                            attributes = @{
                                order        = 7
                                name         = 'DNS Records'
                                kind         = 'Textbox'
                                hint         = 'Table of DNS records in the zone'
                                required     = $true
                                show_in_list = $false
                            }
                        }
                    )
                }
            }
        }
    }
    $Body = $Body | ConvertTo-Json -Depth 6
    New-ITGlueWebRequest -Endpoint 'flexible_asset_types' -Method 'POST' -Body $Body
}