# Active Directory Automation

Getting accurate information for Active Directory environments is crucial to properly support your clients. Let's look at a script that can automate the discovery of your AD environment, create a Flex Asset in IT Glue, *and* continue to update that same flex asset by simply re-running the script on a scheduled basis.

## Setup Instructions

:warning: If you intend to use this script's API functionality, make sure you have installed the [IT Glue PowerShell Module](https://github.com/itglue/powershellwrapper)

:warning: Make sure your Active Directory flexible asset type in IT Glue has fields corresponding to the ones outlined in `ActiveDirectory.flexasset`, as that is the data that this script is capable of finding.

This script makes use of a configuration file to hold neccessary data that the API needs to be able to create and modify flexible assets. In the simplest form, that configuration file looks like:

```posh
@{
    flex_asset_id = ''
    org_id = ''
    flexible_asset_type_id = ''

    key_name_ADForestName = ''
    key_name_ADFunctionalLevel = ''
    key_name_DomainName = ''
    key_name_DomainShortName = ''
    key_name_SchemaMaster = ''
    key_name_DomainNamingMaster = ''
    key_name_RIDMaster = ''
    key_name_PDCEmulator = ''
    key_name_InfrastructureMaster = ''
    key_name_GlobalCatalogServers = ''


}
```

In order to get started easily, an `Initialize-ActiveDirectoryFlexAsset.ps1` script has been created. Running this script will automatically create a new Flexible Asset Template in your IT Glue account and generate a `config.psd1` configuration file.

If you wish to modify an existing flexible asset type rather than creating a new one, please see the [Advanced Configuration](https://github.com/itglue/automation/blob/master/Active%20Directory/Advanced%20Configuration.md) instructions.

:warning: Although this configuration is a one-time process, the `$org_id` parameter in the configuration file must be updated for each organization you wish to run the script for. You can find this organization id by navigating to the organization page in IT Glue and looking at the URL in your web browser. If the page is `https://subdomain.itglue.com/1234567`, the organization id is `1234567`.

Once you are done, save your configuration file in the same directory as your script and make sure to pass the name of the file into the script using the `-api <file path>` parameter if you want your script to automatically send data to IT Glue.

## Running the script for the first time

After following the setup instructions, it is time to run your script. There are a few things to note:

:warning: This script assumes that the servers it tags are in IT Glue as Configurations and that there is an exact name match. For example, if a Global Catalog server is named "East-DC-2", this script expects to have a configuration item in IT Glue under the current organization that has a name of "East-DC-2". If this is not the case, the script will fail to appropriately create or update the flex asset.

Once your configuration file is appropriately set up, all you need to do is run the script with `.\ActiveDirectory.ps1 -api api_config-ActiveDirectory.psd1` and the script will take care of the rest, including auto-updating the config document with the flexible asset id that is created.

NOTE: Every organization in IT Glue has a specific id attached to it. If you are unaware of the id for the organization or client you are getting AD information for, you are welcome to use the scripts `-organization <string>` parameter. For example, if you are running this script at a client who's name in IT Glue is `Happy Frog`, you can run the script with `.\ActiveDirectory.ps1 -api api_config-ActiveDirectory.psd1 -organization "Happy Frog"`, and the script will automatically find the organization id. Do note that it looks for an **exact** match for the organization name.

After you have run the script for the first time, you are welcome to re-run it as often as you please to capture any changes and update the flex asset in IT Glue. Since the flex asset id is automatically updated in the config file, this script will be able to handle everything without manual intervention. For example, you might want to set up a scheduled task to run `.\ActiveDirectory.ps1 -api api_config-ActiveDirectory.psd1` on a weekly or monthly basis to make sure any changes are properly reflected in IT Glue.

----

:heart: Documentation Automation!