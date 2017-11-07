<#

.SYNOPSIS
This script grabs all installed programs/applications and then compares them to a list of known programs of interest.
This is useful for discovering if common applications like QuickBooks or ShadowProtect are present during initial auditing.

.DESCRIPTION
Options:

    -help - Display the current help menu
    -applications <string> - Give an XML file listing all applications of interest
    -silent - Run the script without printing anything
    -api <string> - Declare a file name for an API config file to post flex asset directly to IT Glue 
    -file <string> - Declare a location to save script output to as a csv
    -organization <string> - Declare the name of the organization

.EXAMPLE
./FindApps.ps1 -applications C:/apps.xml
./FindApps.ps1 -app applist.xml -silent -api api_config-Applications.psd1
./FindApps.ps1 -a input.xml -s -file C:/output.csv

.NOTES
Author: Mark Jacobs
Author: Caleb Albers

.LINK
https://github.com/KeystoneIT/Documentation-Scripts

#>


Param (
    [switch]$help = $False,
    [switch]$applications = ""
    [switch]$silent = $False,
    [switch]$continuum = $False,
    [string]$api,
    [string]$file,
    [string]$organization = ""
)

# Get Known Application List
[xml]$Applist = Get-Content $applications

# Print Results
function writeOutput {
    Write-Host "Organization Name:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $organization "`n"

    Write-Host "Application Name:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Name "`n"

    Write-Host "Version:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Version "`n"

    Write-Host "Publisher:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Publisher "`n"

    Write-Host "Install Date:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Installed "`n"

    Write-Host "Category:  `t" -ForegroundColor Gray -NoNewline
    Write-Host "`t `t" $Category[$i] "`n"

    Write-Host $('=' * 50)
}

function updateAPIConfigFile {
    
    $api__flex_asset_type_id = $api_config.flexible_asset_type_id
    
    $api__key_name_ApplicationName = $api_config.key_name_ApplicationName
    $api__key_name_Version = $api_config.key_name_Version
    $api__key_name_Publisher = $api_config.key_name_Publisher
    $api__key_name_Category = $api_config.key_name_Category
    
    
@"
@{
        org_id = '$api__org_id'
        flexible_asset_type_id = '$api__flex_asset_type_id'
    
        key_name_ApplicationName = '$api__key_name_ApplicationName'
        key_name_Version = '$api__key_name_Version'
        key_name_Publisher = '$api__key_name_Publisher'
        key_name_Category = '$api__key_name_Category'
}
"@ | Out-File -FilePath $api -Force
}
    
function formatAPIData {
    
    $api__flex_asset_type_id = $api_config.flexible_asset_type_id
    
    $api__key_name_ApplicationName = $api_config.key_name_ApplicationName
    $api__key_name_Version = $api_config.key_name_Version
    $api__key_name_Publisher = $api_config.key_name_Publisher
    $api__key_name_Category = $api_config.key_name_Category
    

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

    $api__body = @{
        data = @{
            type = "flexible_assets"
            attributes = @{
                organization_id = $api__org_id
                flexible_asset_type_id = $api_config.flexible_asset_type_id
                traits = @{
                    $api__key_name_ApplicationName = $Name
                    $api__key_name_Version = $Version
                    $api__key_name_Publisher = $Publisher
                    $api__key_name_Category = $category[$i]
                }
            }
        }
    }

    return $api__body
}


if($help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit
}

if(($silent) -and !($api -or $file -or $ftp)) {
    Write-Error -Message "ERROR: Using the silent flag requires a URL, FTP server, or location to save results to." `
    -Category InvalidOperation `
}
else {
    $i=0

    $app = $Applist.Applications.software| select -ExpandProperty name
    $category = $Applist.Applications.software| select -ExpandProperty category
    $length = $print.Length

    while($i -lt $length){
        ForEach ($inApp in $inApps){
            $Name = $inApp.DisplayName

            if($Name -eq $app[$i]){
                $Version = $inApp.DisplayVersion
                $Publisher = $inApp.Publisher
                $Installed = $inApp.InstallDate

                if(!$silent){writeOutput}

                if($url -or $file -or $ftp) {
                    $PostData= @{
                        organization = $organization; `
                        ApplicationName = $Name; `
                        Version = $Version; `
                        Publisher = $Publisher; `
                        Category = $category[$i];
                    }
                if($url){
                    Invoke-WebRequest -Uri $url -Method POST -Body $PostData
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

                        Write-Host "Applications flex asset configuration file found!" -ForegroundColor Green

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
                        Write-Error "ERROR: Applications flex asset configuration file was found. Please create one and re-run the script."
                    }
                }
            }
        } $i++ # Increment counter to check the next application
    }

    if($file){
        $SaveData | export-csv -Path $file -NoTypeInformation
    }
}