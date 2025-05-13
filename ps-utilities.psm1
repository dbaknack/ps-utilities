function MergeContext{
    <#
.SYNOPSIS
    Returns planets that match the given name.

.DESCRIPTION
    This function returns a list of solar system planets. You can filter them by name using wildcards.

.PARAMETER Name
    The name of the planet(s) to retrieve. Supports wildcards.

.EXAMPLE
    Get-Planet -Name "M*"

.EXAMPLE
    Get-Planet

.NOTES
    Author: Your Name
#>
param(
    [hashtable]$Target,
    [hashtable]$Defaults
)

# given the defaults, add it to the target if not already there
foreach ($key in $Defaults.Keys) {
    # if the key is not in the target, add it
    if (-not $Target.ContainsKey($key)) {
        $Target[$key] = $Defaults[$key]
    }
    # do this for all default keys
    elseif ($Target[$key] -is [hashtable] -and $Defaults[$key] -is [hashtable]) {
        MergeContext -Target $Target[$key] -Defaults $Defaults[$key]
    }
}
}
function Context{
param([hashtable]$fromSender)

if(-not $fromSender){$fromSender = @{}}
$defaults = @{
    Preferences = @{
        ErrorAction = "Stop"
        Messages = @{
            Enabled = $true
            User            = @{ Enabled = $true;   Color = "Cyan"      }
            Development     = @{ Enabled = $false;  Color = "Magenta"   }
            Test            = @{ Enabled = $false;  Color = "Yellow"    }
            Informational   = @{ Enabled = $true;   Color = "Cyan"      }
            Success         = @{ Enabled = $true;   Color = "Green"     }
            Warning         = @{ Enabled = $true;   Color = "Yellow"    }
            Internal        = @{ Enabled = $false;  Color = "Magenta"   }
        }
    }
    Message = @{
        Type        = "Informational"
        UserName    = [System.Environment]::UserName
        From        = "NameNotProvided"
        DateTime    = {(Get-Date).toString('yyyy-MM-dd HH:mm:ss.fff')}
        Text        = "no-message"
    }
}
MergeContext -Target $fromSender -Defaults $defaults

return $fromSender
}
function Message{
param([hashtable]$fromSender)
if(-not $fromSender){
    $fromSender = @{}
}

# merger the context with properties supplied
Context $fromSender | out-null

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
function ConvertObjectJsontoHashtable{
param($object)

$hashTable = @{}
if(($object.gettype()).name -eq 'pscustomobject'){
    foreach($property in $object.psobject.properties){
        if($null -eq $property.value){
            $hashTable[$property.name] = ConvertObjectJsontoHashtable -object ""    
        }else{
            $hashTable[$property.name] = ConvertObjectJsontoHashtable -object $property.value
        }
    }
}else{
    return $object
}
return  $hashtable
}
function ConvertfromJsonToHashtable{
param([hashtable]$fromSender)
$ErrorActionPreference = "Stop"
if($null -eq $fromSender){
    $fromSender = @{}
}
$path = $fromSender.Path

try{
    $content = get-content -path $path -ErrorAction Stop
}catch{

}


$jsonObj = ($content | convertfrom-json)

return ConvertObjectJsontoHashtable $jsonObj
}
function Invoke-UDFSQLCommand{
param([hashtable]$fromSender)

# databasename is not required, but if not supplied, master will be default
if(-not($fromSender.ContainsKey('DatabaseName'))){
    $fromSender += @{DatabaseName = 'Master'}
}

# processname is not required, but if not supplied, default will be used
if(-not($fromSender.ContainsKey('ProcessName'))){
    $fromSender += @{ProcessName = 'Invoke-UDFSQLCommand2'}
}

# if testconnection is supplied a test connection will be made
if($fromSender.ContainsKey('TestConnection')){
    $fromSender = @{TestConnection = $true}
    
}else{
    $fromSender += @{TestConnection = $false}
}
if($fromSender.TestConnection){
    $fromSender += @{Query = "select Test = cast(1 as bit)"}
}

# will attempt to make the connection
try{
    $processname            = $fromSender.ProcessName
    $myQuery                = "{0}" -f $fromSender.Query
    $sqlconnectionstring    = "
        server                          = $($fromSender.InstanceName);
        database                        = $($fromSender.DatabaseName);
        trusted_connection              = true;
        application name                = $processname;"
    # sql connection, setup call
    $sqlconnection                  = new-object system.data.sqlclient.sqlconnection
    $sqlconnection.connectionstring = $sqlconnectionstring
    $sqlconnection.open()
}catch{
    return $Error[0]
}

$sqlcommand                     = new-object system.data.sqlclient.sqlcommand
$sqlcommand.connection          = $sqlconnection
$sqlcommand.commandtext         = $myQuery
# sql connection, handle returned results
$sqladapter                     = new-object system.data.sqlclient.sqldataadapter
$sqladapter.selectcommand       = $sqlcommand
$dataset                        = new-object system.data.dataset
$sqladapter.fill($dataset) | out-null
$resultsreturned                = $null
$resultsreturned               += $dataset.tables
$sqlconnection.close()
$sqlconnection.dispose()
return $resultsreturned.Rows
}