Write-Host "running on-import.ps1"
Clear-Host
# read in configuration 
_ReadConfig

# update configuration 
(PSUtilConfig).Preferences.Messages.Enabled = $true
(PSUtilConfig).Preferences.Internal.Enabled = $true


Write-Host "Module Name: ps-utilities" -ForegroundColor "Magenta"
Write-Host "Version: 1.0.3" -ForegroundColor "Magenta"
Write-Host ""
Write-Host "initializing.." -ForegroundColor "Magenta"
Write-Host ""

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
