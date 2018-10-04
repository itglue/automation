<#

Initialize-ActiveDirectoryFlexAsset.ps1

This script creates a new flexible asset type in IT Glue with all the fields neccessary for the Active Directory script to run.
It also generates a configuration file that can be used to run the Active Directory data collection script.

Keep in mind that the configuration file generated still needs to have an organization id manually added.

This script creates the Flexible Asset Type with the name "Active Directory". If an existing Flexible Asset Type with that
name is present, it will ask you if you wish to rename the existing record. If so, it will be renamed "Active Directory (OLD)".
No data will be lost in this -- the flexible asset type will simply be renamed. If you select NO, a flexible asset type with
the name "Active Directory [AUTO]" will be created. You may rename this in the IT Glue Admin Panel at any time.

#>



try {
    Import-Module ITGlueAPI
}
catch {
    Write-Error "Failed to import the ITGlueAPI module. Is it installed?"
    Exit
}

# Check if a flex asset with the name "Active Directory" already exists
$existing_FATs = Get-ITGlueFlexibleAssetTypes
$ad_fat_name = "Active Directory"

$existing_ad_fat = $existing_FATs.data | Where-Object {$_.attributes.name -eq "Active Directory"}

if($existing_ad_fat) {
    Write-Host 'A flexible asset type with the name "Active Directory" already exists. Would you like to rename the existing flexible asset type to "Active Directory (OLD)"? This is an optional operation, and no data will be lost.'

    $yes = New-Object Management.Automation.Host.ChoiceDescription '&Yes'
    $no  = New-Object Management.Automation.Host.ChoiceDescription '&No'
    $options = [Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $default = 1  # $no

    $answer = $Host.UI.PromptForChoice($title, $msg, $options, $default)

    if($answer) {
        Write-Host 'No was selected. A new flexible asset type with the name "Active Directory [AUTO]" will be created. You can rename it at any time from the IT Glue Admin panel.'
        $ad_fat_name = "Active Directory [AUTO]"
    }
    else {
        $renamed_AD = @{
            type = 'flexible_asset_types'
            attributes = @{
                name = 'Active Directory (OLD)'
            }
        }
        try {
            $output = Set-ITGlueFlexibleAssetTypes -data $renamed_AD -id $existing_ad_fat.id
        }
        catch {
            Throw "Flexible Asset Type rename failed. Please change the name in the IT Glue Admin panel, or try again."
        }
    }
}


$data = @{
    type = 'flexible_asset_types'
    attributes = @{
        name = $ad_fat_name
        description = ''
        icon = 'windows'
        show_in_menu = $true
        enabled = $true
    }
    relationships = @{
        flexible_asset_fields = @{
            data = @(
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 1
                        name = 'Forest Name'
                        kind = 'Text'
                        hint = 'Full forest name - e.g. domain.com'
                        default_value = ''
                        required = $true
                        show_in_list = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 2
                        name = 'Domain Full Name'
                        kind = 'Text'
                        hint = 'Full Active Directory domain name - e.g. corp.domain.com'
                        default_value = ''
                        required = $true
                        show_in_list = $true
                        use_for_title = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 3
                        name = 'Domain Short Name'
                        kind = 'Text'
                        hint = 'Short Active Directory domain name - e.g. CORP'
                        default_value = ''
                        required = $true
                        show_in_list = $true
                        use_for_title = $true
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 4
                        name = 'AD Level'
                        kind = 'Select'
                        hint = 'Forest Functional Level'
                        default_value = "2000`r`n" `
                                    + "2003`r`n" `
                                    + "2008`r`n" `
                                    + "2008 R2`r`n" `
                                    + "2012`r`n" `
                                    + "2012 R2`r`n" `
                                    + "2016`r`n"
                        required = $true
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 5
                        name = 'Schema Master'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 6
                        name = 'Domain Naming Master'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 7
                        name = 'Relative ID (RID) Master'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 8
                        name = 'PDC Emulator Master'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 9
                        name = 'Infrastructure Master'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 10
                        name = 'Global Catalog Servers (Domain Controllers)'
                        kind = 'Tag'
                        tag_type = 'Configurations'
                        required = $false
                        show_in_list = $false
                    }
                },
                @{
                    type = 'flexible_asset_fields'
                    attributes = @{
                        order = 11
                        name = 'Notes'
                        kind = 'Textbox'
                        required = $false
                        show_in_list = $false
                    }
                }
            )
        }
    }
}


try {
    $output = New-ITGlueFlexibleAssetTypes -data $data
}
catch {
    Throw "Unable to create Flexible Asset Type."
}

if($output) {
    Write-Host "Active Directory Flexible Asset Type successfully created."

    $fat_id = $output.data.id

    $configuration = @"
@{
    # REQUIRED
    org_id = ''

    # Auto-Generated
    flexible_asset_type_id = '$fat_id'

    key_name_ADForestName = 'forest-name'
    key_name_ADFunctionalLevel = 'ad-level'
    key_name_DomainName = 'domain-full-name'
    key_name_DomainShortName = 'domain-short-name'
    key_name_SchemaMaster = 'schema-master'
    key_name_DomainNamingMaster = 'domain-naming-master'
    key_name_RIDMaster = 'relative-id-rid-master'
    key_name_PDCEmulator = 'pdc-emulator-master'
    key_name_InfrastructureMaster = 'infrastructure-master'
    key_name_GlobalCatalogServers = 'global-catalog-servers-domain-controllers'

}
"@

    try {
    $configuration | Out-File -FilePath ("config.psd1") -Force
    }
    catch {
        Write-Error "Configuration file failed to save. Printing the file for easy reference:"
    }
    
    Write-Host $configuration -ForegroundColor "Green"
}