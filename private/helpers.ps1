write-host "running private/helpers.ps1"

function _ModuleRoot{
    $ModulePath = $PSScriptRoot
    $ParentPath = Split-Path -Path $ModulePath -Parent
    return $ParentPath
}

#  run this on import to define $global:config
function _ReadConfig{
   $path = join-path  (_ModuleRoot) (join-path "config" "defaults.json")
   $global:config = (ConvertfromJsonToHashtable  @{Path  = $path})
}

<#
_NewStore  @{
    For = "ps-utilities"
    Stores = @(
        @{Name = "Servers"}
        @{Name = "Config"}
    )
}
_RemoveStore  @{
    For = 'ps-utilities'
    Stores = @(
        @{Name = "Config"}
    )
}
_InsertTo @{
    For = 'ps-utilities'
    Stores = @(
        @{
            Name = "Servers"
            Items = @(
                [pscustomobject]@{},
                [pscustomobject]@{}
            )
        }
    )
}
_GetFromStore @{
    For = 'ps-utilities'
    Stores = @(
        @{Name = 'Servers'}
        @{Name = 'Config'}
    )
}

#>