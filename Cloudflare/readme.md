# CloudflareITGlue Powershell Module

## What does this do

- Sync Cloudflare DNS Zones to ITGlue Client Organizations as Flex Assets

![screenshot](https://user-images.githubusercontent.com/43423017/60233728-61630700-9856-11e9-899c-54178c746463.png)

>**Name:** Name of the Cloudflare DNS Zone  
>**Last Sync:** UTC datestamp  
>**Nameservers:** Nameservers designated by Cloudflare  
>**Status:** Status of the Cloudflare DNS Zone  
>**Zone File:** BIND format zone file  
>**DNS Records:** Table of all DNS records in the zone and a link to the zone page in Cloudflare  
>**Related Items:** Domain Tracker Tag  
>**Revisions:** Flex assets contain revision history by nature (Cloudflare does not!)  

- [Installing the module](#Installing-the-module)
- [API authorization](#API-Authorization)
- [Usage](#Usage)
- [Version info](#Version-History)

## Configuration

### Installing the module

Copy the CloudflareITGlue module folder into the Powershell module directory, default path:  
>`C:\Program Files\WindowsPowerShell\Modules\CloudflareITGlue`

### API authorization

#### Obtain API keys

- Cloudflare
  - Login to Cloudflare.
  - Go to **My Profile**.
  - Scroll down to **API Keys** and locate _Global API Key_.
  - Select **API Key**.

- ITGlue
  - Login to ITGlue.
  - Select the **Account** tab.
  - Select the **API Keys** tab.
  - Click the **+** symbol to add a new API key.
  - **Enter Name**.
  - Select **Generate API Key**

#### Add authorization

```powershell
Add-CloudflareITGlueAPIAuth
```

>This will prompt you for your API keys and Cloudflare email. The API keys will be encrypted with your user account and stored in the module directory. Requires elevated permissions for file creation.  

#### Viewing/Removing authorization info

```powershell
Get-CloudflareITGlueAPIAuth
Remove-CloudflareITGlueAPIAuth
```

>Use these to view/delete the auth that's been entered.  
>API keys are not shown in full. Removal requires elevated permissions to delete file.  

## Usage

```powershell
Sync-CloudflareITGlueFlexibleAssets
```

>This command will create a new flex asset type in ITGlue called Cloudflare DNS.  
>It will then match Cloudflare zones to ITGlue orgs using the Domain Tracker and sync the zones to their respective ITGlue organizations.  
>Cloudflare zones that are not in the Domain Tracker will be output to the console and log file.  
>Set this up to run at an interval of your choosing however you like.  
>
>There is optional logging functionality:  
>`Sync-CloudflareITGlueFlexibleAssets -Log 'C:\Temp\cfitg.log'`  
>
>You can use a custom name for the flex asset type via the optional FlexAssetType parameter:  
>`Sync-CloudflareITGlueFlexibleAssets -FlexAssetType 'My Cloudflare DNS'`  

- Heres a quick Powershell script you can use to create a scheduled task:  

>```powershell
>$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
>    -Argument '-NoProfile -WindowStyle Hidden -Command "& Sync-CloudflareITGlueFlexibleAssets -Log C:\Temp\cfitg.log"'
>$Trigger = New-ScheduledTaskTrigger -Daily -At 8am
>$Principal = New-ScheduledTaskPrincipal -UserID '%USERNAME%' -LogonType S4U
>Register-ScheduledTask -TaskName 'Sync zones' -Action $Action -Trigger $Trigger -Principal $Principal
># Be sure you've added auth info for %USERNAME%
>```

## Version info

- 1.0
  - Dns zones are matched to ITGlue orgs via custom txt record mechanism
- 1.1
  - Dns zones are matched to ITGlue orgs automatically via Domain tracker
- 1.2
  - Full logging functionality
  - Files with the same name in ITGlue on a flex asset do not appear to be unique, revision history only shows the latest file, Zone files now have a unique filename via utc timestamp and revision history now keeps copies of each file
  - Running the sync command automatically creates the flex asset type if it does not exist
  - Related items tagging
  - Lowered Cloudflare request buffer
  - Re: Zone file export format
    - Cloudflare export format changed, modified to account for this
    - Upon import/upload, it is normal for Cloudflare to show an error when reading the SOA record. All records are imported correctly and the SOA is not configurable by Cloudflare. The same behavior happens with an unmodified zone file export

## References

[Invoke-RestMethod Documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod/)  
[ITGlue API Documentation](https://api.itglue.com/developer/)  
[Cloudflare API Documentation](https://api.cloudflare.com/)  
