write-host "running on-import.ps1"
clear-host
# read in configuration 
_ReadConfig

# update configuration 
(PSUtilConfig).Preferences.Messages.Enabled = $true
(PSUtilConfig).Preferences.Internal.Enabled = $true


Write-host "Module Name: ps-utilities" -fore "magenta"
Write-host "Version: 1.0.3" -fore "magenta"
Write-host ""
Write-host "initializing.." -fore "magenta"
write-host ""

Message2 @{
    Type = "Internal"
    From = "run/on-import"
    Text = "_ReadConfig > ps-utilities configuration imported"
}

# ps-utilities sets up its root directory
SetUpRootDirectory @{For = 'ps-utilities'}


Message2 @{
    Type = "Internal"
    From = "run/on-import"
    Text = "creating the default ps-utilites directory"
}
# setup a store root directory for ps-utilities
SetupStoresDirectory @{For = 'ps-utilities'}

Message2 @{
    Type = "Internal"
    From = "run/on-import"
    Text = "creating the default ps-utilites schemas directory"
}
# setup the schemas folder and file for ps-utilities names schemas.json
SetUpSchemasDirectory @{For = 'ps-utilities'}

Message2 @{
    Type = "Internal"
    From = "run/on-import"
    Text = "creating the default ps-utilites schemas file"
}
CreateSchemasFile @{In = 'ps-utilities';Name = "schemas.json"}

# update the internals configuration back to false
(PSUtilConfig).Preferences.Internal.Enabled = $false