# CloudflareITGlue Powershell Module

## What does this do

- Sync Cloudflare DNS Zones to ITGlue Client Organizations as Flex Assets

![screenshot](https://user-images.githubusercontent.com/43423017/48573233-6e7f4700-e8c0-11e8-8dd1-793e06620e96.png)

>**Name:** Name of the Cloudflare DNS Zone  
>**Last Sync:** Timestamp when flex asset is created/updated  
>**Nameservers:** Nameservers designated by Cloudflare  
>**Status:** Status of the Cloudflare DNS Zone  
>**Zone File:** BIND format zone file  
>**Domain Tracker:** Domain Tracker Tag  
>**DNS Records:** Table of all DNS records in the zone and a link to the zone page in Cloudflare  
>**Revisions:** Flex assets contain revision history by nature  

## How it works

- Configure
- Schedule the sync command to run at a desired interval

## Configuration

[Installing the module](#installing-the-module)  
[API Authorization](#api-authorization)  
[Creating the ITGlue Flex Asset Type](#creating-the-itglue-flex-asset-type)  

### Installing the module

Copy the CloudflareITGlue module folder into the Powershell module directory  
>`C:\Program Files\WindowsPowerShell\Modules\CloudflareITGlue`

### API Authorization

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

### Creating the ITGlue Flex Asset Type

```powershell
New-CloudflareITGlueFlexAssetType
```

>This will create a new Flex Asset Type in ITGlue called **Cloudflare DNS**.  
>Customize your ITGlue sidebar in the **Account > Settings > General > Customize Sidebar** section.  
>If you need to use a different name there is an optional parameter:  
>`New-CloudflareITGlueFlexAssetType -Name 'My Cloudflare DNS'`  

## Usage

```powershell
Sync-CloudflareITGlueFlexibleAssets
```

>This command will match Cloudflare zones to ITGlue orgs using the Domain Tracker then sync the zones as flex assets to their respective organizations.  
>Cloudflare zones that are not in the Domain Tracker will be output to the console.  
>If you used a custom name for the flex asset type, you'll also need to pass it to the sync command via the optional FlexAssetType parameter:  
>`Sync-CloudflareITGlueFlexibleAssets -FlexAssetType 'My Cloudflare DNS'`  

Set this up to run at an interval of your choosing however you like.  

- Heres a quick Powershell script you can use to create a scheduled task:  

>```powershell
>$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
>    -Argument '-NoProfile -WindowStyle Hidden -Command "& Sync-CloudflareITGlueFlexibleAssets"'
>$Trigger = New-ScheduledTaskTrigger -Daily -At 8am
>$Principal = New-ScheduledTaskPrincipal -UserID '%username%' -LogonType S4U
>Register-ScheduledTask -TaskName 'Sync zones' -Action $Action -Trigger $Trigger -Principal $Principal
># Be sure you've added auth info for %username%
>```

## References

[Invoke-RestMethod Documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod/)  
[ITGlue API Documentation](https://api.itglue.com/developer/)  
[Cloudflare API Documentation](https://api.cloudflare.com/)  
>On Cloudflare Rate Limiting: "The Cloudflare API sets a maximum of 1,200 requests in a five minute period."  
>You may still see the odd gateway timeout even though the rate limit is accounted for.  
