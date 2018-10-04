<#

.SYNOPSIS
This script grabs all domains in the current forest along with servers hosting all FSMO roles for each domain

.DESCRIPTION
Options:

    -help               - Display the current help menu
    -silent             - Run the script without printing anything
    -FQDN               - Show Fully Qualified Domain Name (server.domain.tld) instead of hostname
    -Organization       - Attempt an auto-match based on organization name (must be an exact match to what exists in IT Glue)
    -api  <string>      - Declare a file name for an API config file to post flex asset directly to IT Glue 
    -file <string>      - Declare a location to save script output to as a csv

.EXAMPLE
./ADScraper.ps1 -s -api "api_config-ActiveDirectory.ps1"
./ADScraper.ps1 -FQDN -file "C:\adout.csv"

.NOTES
Author: Caleb Albers

If you wish to use the -api parameter to upload results directly to IT Glue, make sure you have the IT Glue PowerShell module installed and configured (https://github.com/itglue/powershellwrapper)

.LINK
https://github.com/itglue/automation

#>

Param (
    [switch]$help = $False,
    [switch]$silent = $False,
    [switch]$FQDN = $False,
    [string]$api = "",
    [string]$file = "",
    [string]$organization = ""
)


try {
    Import-Module ActiveDirectory
}
catch {
    Write-Error "The Active Directory module could not be imported. Please make sure it is installed."
}


# Print results
function writeOutput {
    Write-Host "Organization Name...  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $organization "`n"

    Write-Host "Forest Name...  `t   `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t" $ADForestName "`n"

    Write-Host "Getting AD Functional Level..." -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $ADFunctionalLevel "`n"

    Write-Host "Getting AD Full Name...  " -ForegroundColor Green -NoNewline
    Write-Host "`t `t" $Domain "`n"

    Write-Host "Getting AD Short Name... `t" -ForegroundColor Green -NoNewline
    Write-Host "`t" $ADShortName "`n"

    Write-Host "Getting FSMO Roles..." -ForegroundColor Green

    Write-Host "`t Schema Master:         `t " -ForegroundColor Yellow -NoNewline
    Write-Host $SchemaMaster

    Write-Host "`t Domain Naming Master:   `t " -ForegroundColor Yellow -NoNewline
    Write-Host $DomainNamingMaster

    Write-Host "`t Relative ID (RID) Master:   `t " -ForegroundColor Yellow -NoNewline
    Write-Host $RIDMaster

    Write-Host "`t PDC Emulator:           `t " -ForegroundColor Yellow -NoNewline
    Write-Host $PDCEmulator

    Write-Host "`t Infrastructure Master: `t " -ForegroundColor Yellow -NoNewline
    Write-Host $InfrastructureMaster "`n"

    Write-Host "Getting Global Catalog Servers (Domain Controllers)..." -ForegroundColor Green
    $GlobalCatalogs
}

function updateAPIConfigFile {

    $api__flex_asset_type_id = $api_config.flexible_asset_type_id

    $api__key_name_ADForestName = $api_config.key_name_ADForestName
    $api__key_name_ADFunctionalLevel = $api_config.key_name_ADFunctionalLevel
    $api__key_name_DomainName = $api_config.key_name_DomainName
    $api__key_name_DomainShortName = $api_config.key_name_DomainShortName
    $api__key_name_SchemaMaster = $api_config.key_name_SchemaMaster
    $api__key_name_DomainNamingMaster = $api_config.key_name_DomainNamingMaster
    $api__key_name_RIDMaster = $api_config.key_name_RIDMaster
    $api__key_name_PDCEmulator = $api_config.key_name_PDCEmulator
    $api__key_name_InfrastructureMaster = $api_config.key_name_InfrastructureMaster
    $api__key_name_GlobalCatalogServers = $api_config.key_name_GlobalCatalogServers


@"
@{
    org_id = '$api__org_id'
    flexible_asset_type_id = '$api__flex_asset_type_id'

    key_name_ADForestName = '$api__key_name_ADForestName'
    key_name_ADFunctionalLevel = '$api__key_name_ADFunctionalLevel'
    key_name_DomainName = '$api__key_name_DomainName'
    key_name_DomainShortName = '$api__key_name_DomainShortName'
    key_name_SchemaMaster = '$api__key_name_SchemaMaster'
    key_name_DomainNamingMaster = '$api__key_name_DomainNamingMaster'
    key_name_RIDMaster = '$api__key_name_RIDMaster'
    key_name_PDCEmulator = '$api__key_name_PDCEmulator'
    key_name_InfrastructureMaster = '$api__key_name_InfrastructureMaster'
    key_name_GlobalCatalogServers = '$api__key_name_GlobalCatalogServers'


}
"@ | Out-File -FilePath $api -Force
}

function formatAPIData {

    $api__flex_asset_id = $api_config.flex_asset_id
    $api__flex_asset_type_id = $api_config.flexible_asset_type_id

    $api__key_name_ADForestName = $api_config.key_name_ADForestName
    $api__key_name_ADFunctionalLevel = $api_config.key_name_ADFunctionalLevel
    $api__key_name_DomainName = $api_config.key_name_DomainName
    $api__key_name_DomainShortName = $api_config.key_name_DomainShortName
    $api__key_name_SchemaMaster = $api_config.key_name_SchemaMaster
    $api__key_name_DomainNamingMaster = $api_config.key_name_DomainNamingMaster
    $api__key_name_RIDMaster = $api_config.key_name_RIDMaster
    $api__key_name_PDCEmulator = $api_config.key_name_PDCEmulator
    $api__key_name_InfrastructureMaster = $api_config.key_name_InfrastructureMaster
    $api__key_name_GlobalCatalogServers = $api_config.key_name_GlobalCatalogServers




    if($api_config.org_id) {
        $api__org_id = $api_config.org_id
    }
    elseif($organization) {

        Write-Host "No organization id was specified in the config file, attempting an `
        auto-match based on the name: " $organization -ForegroundColor Yellow

        $attempted_match = Get-ITGlueOrganizations -filter_name "$organization"

        if($attempted_match.data[0].attributes.name -eq $organization) {
            Write-Host "Auto-match successful. Updating config file with organization id." -ForegroundColor Green

            $api__org_id = $attempted_match.data.id

            updateAPIConfigFile

        }
        else {
            Write-Error "No auto-match was found. Please pass the exact name to -organization <string> or `
            add the organization id to the config file."

            return
        }
    }
    else {
        Write-Error "No organization id was found. Please add an organization id to the config file `
        or attempt a match by putting the full name in the -organization <string> parameter."

        return
    }

    # Get the ID for each configuration

    $api__SchemaMaster_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $SchemaMaster)[0].data.id
    $api__DomainNamingMaster_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $DomainNamingMaster)[0].data.id
    $api__RIDMaster_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $RIDMaster)[0].data.id
    $api__PDCEmulator_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $PDCEmulator)[0].data.id
    $api__InfrastructureMaster_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $InfrastructureMaster)[0].data.id

    $idx = 0
    $tmp_global_catalog_ids = @(0) * $GlobalCatalogs.split(",").Count

    $GlobalCatalogs.split(",") | ForEach {
        $tmp_global_catalog_ids[$idx] = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $_)[0].data.id
        $idx++
    }

    $api__GlobalCatalogs =  $tmp_global_catalog_ids


    $api__body = @{
        type = "flexible_assets"
        attributes = @{
            organization_id = $api__org_id
            flexible_asset_type_id = $api_config.flexible_asset_type_id
            traits = @{
                $api__key_name_ADForestName = $ADForestName
                $api__key_name_ADFunctionalLevel = $ADFunctionalLevel
                $api__key_name_DomainName = $Domain
                $api__key_name_DomainShortName = $ADShortName
                $api__key_name_SchemaMaster = $api__SchemaMaster_id
                $api__key_name_DomainNamingMaster = $api__DomainNamingMaster_id
                $api__key_name_RIDMaster = $api__RIDMaster_id
                $api__key_name_PDCEmulator = $api__PDCEmulator_id
                $api__key_name_InfrastructureMaster = $api__InfrastructureMaster_id
                $api__key_name_GlobalCatalogServers = $api__GlobalCatalogs
            }
        }
    }

    return $api__body
}

if($help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit
}

if(($silent) -and !($url -or $file -or $ftp)) {
    Write-Error -Message "ERROR: Using the silent flag requires a URL, FTP server, or location to save results to." `
                -Category InvalidOperation `
}
else {
    if($continuum) {
        $organization = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\SAAZOD").SITENAME
    }

    # Get forest info
    if($FQDN) {
        $ADForestName = (Get-ADForest).Name
        $SchemaMaster = (Get-ADForest).SchemaMaster
        $DomainNamingMaster = (Get-ADForest).DomainNamingMaster
    }
    else {
        $ADForestName = ((Get-ADForest).Name).split(".")[0]
        $SchemaMaster = ((Get-ADForest).SchemaMaster).split(".")[0]
        $DomainNamingMaster = ((Get-ADForest).DomainNamingMaster).split(".")[0]
    }
    $FullFunctionalLevel = (Get-ADForest).ForestMode
    switch($FullFunctionalLevel) {
        Windows2000Forest   {$ADFunctionalLevel = "2000"}
        Windows2003Forest   {$ADFunctionalLevel = "2003"}
        Windows2008Forest   {$ADFunctionalLevel = "2008"}
        Windows2008R2Forest {$ADFunctionalLevel = "2008 R2"}
        Windows2012Forest   {$ADFunctionalLevel = "2012"}
        Windows2012R2Forest {$ADFunctionalLevel = "2012 R2"}
        Windows2016Forest   {$ADFunctionalLevel = "2016"}
    }

    # Get Global Catalog Servers (Domain Controllers)
    if($FQDN) {
        $GlobalCatalogs = (Get-ADForest).GlobalCatalogs -join ','
    }
    else {
        $GlobalCatalogList = @((Get-ADForest).GlobalCatalogs)
        $GlobalCatalogs = ""
        for($i = 0; $i -lt ($GlobalCatalogList).Count; $i++) {
            $GlobalCatalogs += (($GlobalCatalogList[$i]).split(".")[0])
            if(($i+1) -ne $GlobalCatalogList.Count) { $GlobalCatalogs += ","}
        }
    }

    # Get domain info
    $Domains = (Get-ADForest).domains
    foreach($Domain in $Domains) {
        $ADShortName = (Get-ADDomain -identity $Domain).Name

        # Get FSMO Roles
        if($FQDN) {
            $RIDMaster = (Get-ADDomain -identity $Domain).RIDMaster
            $PDCEmulator = (Get-ADDOmain -identity $Domain).PDCEmulator
            $InfrastructureMaster = (Get-ADDomain -identity $Domain).InfrastructureMaster
        }
        else {
            $RIDMaster = ((Get-ADDomain -identity $Domain).RIDMaster).split(".")[0]
            $PDCEmulator = ((Get-ADDOmain -identity $Domain).PDCEmulator).split(".")[0]
            $InfrastructureMaster = ((Get-ADDomain -identity $Domain).InfrastructureMaster).split(".")[0]
        }

        if(!$silent){writeOutput}
        if($file -or $ftp) {
                $PostData= @{
                    organization = $organization; `
                    ForestName =$ADForestName; `
                    FunctionalLevel = $ADFunctionalLevel; `
                    DomainName= $Domain; `
                    DomainShortName= $ADShortName; `
                    SchemaMaster= $SchemaMaster; `
                    DomainNamingMaster = $DomainNamingMaster; `
                    RIDMaster = $RIDMaster; `
                    PDCEmulator = $PDCEmulator; `
                    InfrastructureMaster = $InfrastructureMaster; `
                    GlobalCatalogServers = "$GlobalCatalogs";
                 }
        }

        if($api) {
            try {
                Import-Module ITGlueAPI
            }
            catch {
                Write-Error "ERROR: The IT Glue API PowerShell module cannot be imported."
                Write-Error "Please download it from https://github.com/itglue/powershellwrapper, configure it, and try again."
            }

            if(test-path $api) {
                $api_config = Import-LocalizedData -FileName "$api"

                Write-Host "Active Directory flex asset configuration file found!" -ForegroundColor Green

                $api__body = formatAPIData # format data for API call
                $api__org_id = $api__body.attributes.organization_id
                $api__flexible_asset_type_id = $api_config.flexible_asset_type_id
                $api__key_name_DomainName = $api_config.key_name_DomainName

                #find if a flex asset for this domain currently exists
                $currentADFlexAssets = (Get-ITGlueFlexibleAssets -filter_flexible_asset_type_id $api__flexible_asset_type_id -filter_organization_id $api__org_id)

                $api__flex_asset_id = ''
                if($currentADFlexAssets.data.attributes.traits.${api__key_name_DomainName}) {
                    $fa_index = [array]::indexof($currentADFlexAssets.data.attributes.traits.${api__key_name_DomainName} ,$Domain)

                    if($fa_index -ne '-1') {
                        $api__flex_asset_id = $currentADFlexAssets.data[$fa_index].id
                    }
                }

                if($api__flex_asset_id -and $api__org_id) {
                    Write-Host "Flexible Asset id found! Updating the pre-existing flex asset with any new changes."

                    (Set-ITGlueFlexibleAssets -id $api__flex_asset_id -data $api__body).data
                }
                elseif($api__org_id) {
                    Write-Host "No flexible asset id was found... creating a new flexible asset."

                    $api__output_data = New-ITGlueFlexibleAssets -data $api__body

                    $api__output_data.data
                }
            }
            else {
                Write-Error "ERROR: No Active Directory flex asset configuration file was found. Please create one and re-run the script."
            }
        }

        if($file) {
            $SaveData += New-Object PSObject -Property $PostData
        }

    }
    if($file){
        $SaveData | export-csv -Path $file -NoTypeInformation
    }
}