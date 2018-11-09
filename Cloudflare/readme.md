# CloudflareITGlue Powershell Module

## What does this do

- Sync Cloudflare DNS Zones to ITGlue Client Organizations as Flex Assets

![screenshot](https://user-images.githubusercontent.com/43423017/47933412-be5a1900-de91-11e8-805e-d2a27a5f804c.png)

>**Name:** Name of the Cloudflare DNS Zone  
>**Last Sync:** Timestamp when flex asset is created/updated  
>**Nameservers:** Nameservers designated by Cloudflare  
>**Status:** Status of the Cloudflare DNS Zone  
>**Zone File:** BIND format zone file  
>**DNS Records:** Table of all DNS records in the zone  
>**Revisions:** Flex assets contain revision history by nature  

## How it works

- Configure
- Schedule the sync command to run at a desired interval

## Configuration

[Installing the module](#installing-the-module)  
[API Authorization](#api-authorization)  
[Creating the ITGlue Flex Asset Type](#creating-the-itglue-flex-asset-type)  
[Matching Cloudflare DNS Zones to ITGlue Client Orgs](#matching-cloudflare-dns-zones-to-itglue-client-orgs)  

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

### Matching Cloudflare DNS Zones to ITGlue Client Orgs

This is done with TXT records that are easily created/deleted/modified with `Set-CloudflareITGlueClientUIDRecords`  

#### Client UID List

```powershell
Get-ITGlueClientUIDList
```

>This will create and open a txt file in the current directory containing UIDs for all active ITGlue clients.  
>UID format: `OrganizationName__OrganizationId`  

#### Client/Zone Matching Table

```powershell
Get-CloudflareITGlueMatchingTable
```

>This will create and open a csv file in the current directory with the columns `ZoneId`, `ZoneName` & `ITGlueClientUID`.  

#### Matching

>Fill in the `ITGlueClientUID` field in the csv with the corresponding client UIDs obtained in the previous step. Do this for zones you wish to sync to ITGlue.  

#### UID TXT Records

```powershell
Set-CloudflareITGlueClientUIDRecords -MatchingTable ITGlueCloudflareMatchingTable.csv
```

>This command takes the csv and creates/deletes/modifies TXT records called **itglueclientuid** that correspond with whats been entered.  
>Update the csv and run this at anytime to create/delete/modify the TXT records.  
>Use `Get-CloudflareITGlueMatchingTable` for an updated csv, the `ITGlueClientUID` field will correspond with existing TXT records
>and be empty for zones where the TXT record does not exist.  

## Usage

```powershell
Sync-CloudflareITGlueFlexibleAssets
```

>This command will check all zones for the TXT record then create/update the ITGlue flex assets for the respective organizations.  
>Remember `Set-CloudflareITGlueClientUIDRecords` will create, delete and modify the **itglueclientuid** TXT records if you ever need to make changes to which records are syncing or just want to delete the TXT records.  

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

[Cloudflare API Documentation](https://api.cloudflare.com/)  
[ITGlue API Documentation](https://api.itglue.com/developer/)  
[Invoke-RestMethod Documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod/)  
