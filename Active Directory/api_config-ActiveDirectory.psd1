@{

<#

The following variables are specific to the current flex asset and organization, respectively.

If no $org_id is explicitely defined, running the ActiveDirectory.ps1 script with the -organization <string>
parameter will make an attempt at matching that organization name with the names present in IT Glue. An 
exact match is required. If it is found, this configuration file will automatically be updated with the
corresponding $org_id

The $flexible_asset_type_id corresponds to the flexible asset type that represents what an "Active Directory" flex
asset should look like for IT Glue. Please run `(Get-ITGlueFlexibleAssetTypes).data` and find the type id
corresponding to your account's flexible asset type for Active Directory. Additionally, ensure that the proper
fields are present in that template.

#>


# REQUIRED
org_id = ""
# REQUIRED
flexible_asset_type_id = ""



<#

The following fields correspond to the "api" names of the fields needing to be filled out for an Active Directory
flexible asset. These names are found using the `Get-ITGlueFlexibleAssetFields -flex_asset_id <int>` command, replacing
`<int>` with whatever the flex_asset_id is that you specified above in this configuration file. The data that is returned
by the `Get-ITGlueFlexibleAssetFields` command outlines the 'name-key's that need to be entered here. Please review
the README.md file for more information on how to fill this out.


#>

    key_name_ADForestName = ""
    key_name_ADFunctionalLevel = ""
    key_name_DomainName = ""
    key_name_DomainShortName = ""
    key_name_SchemaMaster = ""
    key_name_DomainNamingMaster = ""
    key_name_RIDMaster = ""
    key_name_PDCEmulator = ""
    key_name_InfrastructureMaster = ""
    key_name_GlobalCatalogServers = ""


}