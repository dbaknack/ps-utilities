function MergeContext{
    param(
        [hashtable]$Target,
        [hashtable]$Defaults
    )

    foreach ($key in $Defaults.Keys) {
        if (-not $Target.ContainsKey($key)) {
            $Target[$key] = $Defaults[$key]
        }
        elseif ($Target[$key] -is [hashtable] -and $Defaults[$key] -is [hashtable]) {
            MergeContext -Target $Target[$key] -Defaults $Defaults[$key]
        }
    }
}
function ContextParameters {
    param (
        [hashtable]$Context,
        [string[]]$Mandatory = @(),
        [hashtable]$Optional = @{}
    )

    $missing = @()

    foreach ($paramName in $Mandatory) {
        if (-not $Context.ContainsKey($paramName)) {
            $missing += $paramName
        }
    }

    if ($missing.Count -gt 0) {
        $msg = "Missing mandatory parameters:`n`n - " + ($missing -join "`n - ")
        throw $msg
    }

    foreach ($key in $Optional.Keys) {
        if (-not $Context.ContainsKey($key)) {
            $Context[$key] = $Optional[$key]
        }
    }
    return $Context
}
function Context{
    param([hashtable]$fromSender)

    if(-not $fromSender){$fromSender = @{}}
    $defaults = @{
        Preferences = @{
            ErrorAction = "Stop"
            Messages = @{
                Enabled = $true
                User = @{ Enabled = $true;  Color = "Cyan" }
                Development = @{ Enabled = $false; Color = "Magenta" }
                Test = @{ Enabled = $false; Color = "Yellow" }
                Informational = @{ Enabled = $true;  Color = "Cyan" }
                Success = @{ Enabled = $true;  Color = "Green" }
                Warning = @{ Enabled = $true;  Color = "Yellow" }
            }
        }
        Message = @{
            Type = "Informational"
            UserName = [System.Environment]::UserName
            From = "NameNotProvided"
            DateTime = {(Get-Date).toString('yyyy-MM-dd HH:mm:ss.fff')}
            Text = "no-message"
        }
    }
    MergeContext -Target $fromSender -Defaults $defaults

    return $fromSender
}
function Message{
    param([hashtable]$fromSender)
    if(-not $fromSender){$fromSender = @{}}; Context $fromSender | out-null
    $ErrorActionPreference = $fromSender.Preferences.ErrorAction
    $preferences = $fromSender.Preferences.Messages
    $message = $fromSender.Message

    $text = '"{0}"' -f $message.Text
    if(($preferences.Enabled) -and ($preferences.($message.Type).Enabled)){
        write-host ("[{0}]::[{1}]::[{2}]::{3}" -f @(
            (&$message.DateTime)
            $message.From
            $message.UserName
            $text
        )) -fore $preferences.($message.Type).color
    }
}
function _helperconverttohashtable{
    param($object)

    $hashTable = @{}
    if(($object.gettype()).name -eq 'pscustomobject'){
        foreach($property in $object.psobject.properties){
            $hashTable[$property.name] = _helperconverttohashtable -object $property.value
        }
    }else{
        return $object
    }
   return  $hashtable
}