﻿#
# Module manifest for module 'CloudflareITGlue'
#
# Generated by: Jeremy Colby
#
# Generated on: 06/27/2019
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'CloudflareITGlue.psm1'

    # Version number of this module.
    ModuleVersion     = '1.2.0'
    #   1.0: Matching zones to ITGlue orgs via txt record mechanism
    #   1.1: Matching zones to ITGlue orgs via Domain tracker + minor improvements
    #   1.2: Full logging functionality
    #        Cloudflare's zone file export format changed, modified to account for this
    #           - Also, re Cloudflare zone file import/upload - it is normal for Cloudflare to show error when reading the SOA record from the zone file
    #           - All other records are still imported normally, This happens with an unmodified exported zone files as well - SOA is a backend setting in Cloudflare
    #        Files with the same name in ITGlue on a flex asset are not unique, revision history would only show the newest file,
    #           - Zone files now have unique filename via utc timestamp, revision history keeps copies of each file
    #        Running the sync command automatically creates the flex asset type if it does not exist
    #        Related items tagging
    #        Lowered Cloudflare request buffer
    #        Formatting + minor improvements
    
    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '55a62423-f6e4-4548-ba2a-7387a32ff6d3'

    # Author of this module
    Author            = 'Jeremy Colby'

    # Company or vendor of this module
    # CompanyName       = ''

    # Copyright statement for this module
    Copyright         = '(c) 2019 Jeremy Colby. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Sync Cloudflare DNS Zones to ITGlue Client Organizations as Flex Assets'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0' # New-TemporaryFile seems like only incompatiblity with 4.0

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = 'Private\CloudflareWebRequest.ps1',
    'Private\CloudflareZoneData.ps1',
    'Private\ITGlueWebRequest.ps1',
    'Private\New-CloudflareITGlueFlexAssetType.ps1',
    'Public\CloudflareITGlueAPIAuth.ps1',
    'Public\Sync-CloudflareITGlueFlexibleAssets.ps1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Add-CloudflareITGlueAPIAuth',
    'Get-CloudflareITGlueAPIAuth',
    'Remove-CloudflareITGlueAPIAuth',
    'Sync-CloudflareITGlueFlexibleAssets'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

