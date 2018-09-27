<#

.SYNOPSIS
This script grabs all DHCP servers in a domain and provides their name, status, and scope

.DESCRIPTION
Options:

    -help - Display the current help menu
    -silent - Run the script without printing anything
    -file <string> - Declare a location to save script output to as a csv
    -organization <string> - Declare the name of the organization


.EXAMPLE
./DHCP.ps1 -s -c -url api.example.com
./DHCP.ps1 -FQDN -file C:\adout.csv

.NOTES
Author: Mark Jacobs
Author: Caleb Albers

.LINK
https://github.com/itglue/automation

#>


Param (
    [switch]$help = $False,
    [switch]$silent = $False,
    [switch]$continuum = $False,
    [string]$url,
    [string]$file,
    [string]$organization = ""
)

# Print Results
function writeOutput {
    Write-Host "Organization Name:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $organization "`n"

    Write-Host "DHCP Scope Name:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Name "`n"

    Write-Host "Getting Server Name:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Server "`n"

    Write-Host "Status:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $organization "`n"

    Write-Host "Scope:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Start " - " $End "`n"
}
function updateAPIConfigFile {
    
    $api__flex_asset_type_id = $api_config.flexible_asset_type_id
    
    $api__key_name_ScopeName = $api_config.key_name_ScopeName
    $api__key_name_Server = $api_config.key_name_Server
    $api__key_name_ScopeBounds = $api_config.key_name_ScopeBounds
    
    
@"
@{
        org_id = '$api__org_id'
        flexible_asset_type_id = '$api__flex_asset_type_id'
    
        key_name_ScopeName = '$api__key_name_ScopeName'
        key_name_Server = '$api__key_name_Server'
        key_name_ScopeBounds = '$api__key_name_ScopeBounds'
}
"@ | Out-File -FilePath $api -Force
}
    
function formatAPIData {
    
    $api__flex_asset_type_id = $api_config.flexible_asset_type_id
    
    $api__key_name_ScopeName = $api_config.key_name_ScopeName
    $api__key_name_Server = $api_config.key_name_Server
    $api__key_name_ScopeBounds = $api_config.key_name_ScopeBounds
    

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

    $api__Server_id = (Get-ITGlueConfigurations -filter_organization_id $api__org_id -filter_name $currentServer)[0].id

    $api__body = @{
        type = "flexible_assets"
        attributes = @{
            organization_id = $api__org_id
            flexible_asset_type_id = $api_config.flexible_asset_type_id
            traits = @{
                $api__key_name_ScopeName = $share
                $api__key_name_Server = $api__Server_id
                $api__key_name_ScopeBounds = $Start + " - " + $End
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

    # Get DHCP v4 Scopes
    $DHCPs = Get-DhcpServerv4Scope
    $Server = [System.Net.Dns]::GetHostName()

    ForEach($DHCP in $DHCPs){
        $Start = $DHCP.StartRange
        $End = $DHCP.EndRange
        $Status = $DHCP.State
        $Name = $DHCP.Name

        if(!$silent){writeOutput}

        if($file -or $ftp) {
            $PostData = @{
                Organization = $organization; `
                Name = $Name; `
                Status = $Status; `
                Scope = "$Start - $End"; `
                Server = $Server;
            }
        }
        if($file) {
            $SaveData += New-Object PSObject -Property $PostData
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

                Write-Host "DHCP flex asset configuration file found!" -ForegroundColor Green

                $api__body = formatAPIData # format data for API call
                $api__org_id = $api__body.data.attributes.organization_id
                $api__flex_asset_id = $api_config.flex_asset_id
                
                if($api__org_id) {
                    Write-Host "Creating a new flexible asset."

                    ConvertTo-Json $api__body -Depth 100

                    $api__output_data = New-ITGlueFlexibleAssets -data $api__body

                    $api__output_data
                }
            }
            else {
                Write-Error "ERROR: DHCP flex asset configuration file was found. Please create one and re-run the script."
            }
        }
    }
    if($file) {
        $SaveData | export-csv -Path $file -NoTypeInformation
    }
}