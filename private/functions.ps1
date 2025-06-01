write-host "running private/functions.ps1"
function _UtilityVars{
    return [pscustomobject]@{
        Home = $Home
        ModuleRoot = (_ModuleRoot)
    }

}

function _RemoveStore{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $for = $fromSender.For
    $stores = $fromSender.Stores
    $storesPath = join-path $myHome (join-path $for 'Stores')

    foreach($store in $stores){
        $name = $store.Name
        $path = join-path $storesPath $name
        $path = $path
        if(Test-Path -path $path){
            Remove-item -path $path | out-null
        }
    }
}
function _InsertTo{
    param([hashtable]$fromSender)

    $for = $fromSender.For
    $stores = _GetStores @{For = $for}
    $storesList = $stores.keys
    $myStores = $fromSender.Stores

    foreach($store in $myStores){
        $name = $store.Name
        if($storesList -contains $name){
            $path = $stores.$name.Path
            $content = get-content -path $path
            $object = $content | convertfrom-csv

            $csv = ($object + $store.Items) | convertto-csv
            set-content -path $path -value $csv | out-null
        }
    }
}
