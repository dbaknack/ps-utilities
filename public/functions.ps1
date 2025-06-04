write-host "running public/functions.ps1"
function GetServers{
    $store = "Servers"
    return (
        _GetFromStore @{
        For = 'ps-utilities'
            Stores = @(
                @{Name = $store}
            )
        }
    ).Servers
}
function RemoveServer{
    param([hashtable]$fromSender)

    $where = $fromSender.where
    $property = $fromSender.Property
    $operator = $fromSender.operator

    $store = "Servers"
    $data = @(($utilities.GetFrom(@{Stores = @{Name = $store}})).$store)
    $path = (Context).Stores.$store.Path

    if($data.count -ne 0){
        $new =  switch($operator){
            '-like' {$data | where-object {$_.$where -notlike $property}}
            '-eq'{$data | where-object {$_.$where -ne $property}}
            '-notlike'{$data | where-object {$_.$where -like $property}}
            '-ne'{$data | where-object {$_.$where -eq $property}}
        }
    }else{
        $new = $data
    }
    
    $csv = $new | convertto-csv
    set-content -path $path  -value $csv | out-null
}
function StashServer{
    param([hashtable]$fromSender)
 
    # create the store if it does not exist
    $store = "Servers"
    $script:utilities.NewStore(@{
        Stores = @(@{Name = $store})
    })
    $path = (Context).Stores.$store.Path
    # get the data from the store
    $data = @(($utilities.GetFrom(@{Stores = @{Name = $store}})).$store)
    $servers = $fromSender.Servers

    $entry = @()
    foreach($server in $servers){
        $entryValid = $true
        $duplicateExists = $true
        $missing = @()
        if(-not($server.ContainsKey('DomainName'))){
            $entryValid = $false
            $missing += "DomainName"
        }
        $domainName = $server.DomainName

        if(-not($server.ContainsKey('Name'))){
            $entryValid = $false
            $missing += "Name"
        }
        $name = $server.Name

        if(-not($server.ContainsKey('IP'))){
            $entryValid = $false
            $missing += "IP"
        }
        $ip = $server.IP

        if(-not($server.ContainsKey('Tag'))){
            $server.Add('Tag',$null)
        }
        $tag = $server.Tag
        if($entryValid){
            if($data.count -eq 0){
                $duplicateExists = $false
            }else{
                if($null -eq ($data | where-object {$_.DomainName -eq $domainName -and $_.Name -eq $name -and $_.IP -eq $ip -and $_.Tag -eq $Tag})){
                    $duplicateExists = $false
                }
            }

            if($duplicateExists -eq $false){
                $entry += $server
            }else{
                write-warning ("There is already an entry with DomainName: '{0}', Name: '{1}', IP: '{2}'" -f $domainName,$name,$ip)
            }
        }else{
            $missingList = ($missing -join "`n")
            write-warning ("missing parameters: {0}" -f $missingList)
        }
    }

    foreach($new in $entry){
        $data += $new
    }
    $insert = $data | select-object DomainName,Name,IP,Tag,@{Name = "GUID";Expression = {(New-Guid).guid}}
    $csv = $insert | convertto-csv
    set-content -path $path -value $csv | out-null
}
function MergeContext{
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
function Message2{
    param([hashtable]$fromSender)

    $preferences = (PSUtilConfig).Preferences
    $default = (PSUtilConfig).Functions.Message.default
    $ErrorActionPreference = $preferences.ErrorAction
    
    $isEnabled = $preferences.Messages.Enabled

    if($isEnabled){
        if(-not $fromSender){$fromSender = @{}}

        $message = @{
            Type = [string]
            UserName = [System.Environment]::UserName
            From = [string]
            DateTime = (Get-Date).toString($default.DateTime.Format)
            Text = [string]
        }
    
        if(-not $fromSender.ContainsKey('Type')){
            $message.Type = $default.Type
        }else{
            $message.Type = $fromSender.Type
        }
    
        if(-not $fromSender.ContainsKey('From')){
            $message.From = $default.From
        }else{
            $message.From = $fromSender.From
        }
    
        if(-not $fromSender.ContainsKey('Text')){
            $message.Text = '{0}' -f $default.Text
        }else{
            $message.Text = '{0}' -f $fromSender.Text
        }

        if(($preferences.($message.Type).Enabled)){
            write-host ("[+] [{0}]::[{1}]::[{2}]::[{3}]::[{4}]" -f @(
                $message.Type
                $message.DateTime
                $message.From
                $message.UserName
                $message.Text
            )) -fore $preferences.($message.Type).color
        }
    }

}
function ConvertObjectJsontoHashtable{
    param($object)

    $hashTable = @{}
    if (($object.GetType()).Name -eq 'pscustomobject') {
        foreach ($property in $object.psobject.properties) {
            if ($null -eq $property.value) {
                $hashTable[$property.name] = ConvertObjectJsontoHashtable -object ""
            } else {
                $hashTable[$property.name] = ConvertObjectJsontoHashtable -object $property.value
            }
        }
    } else {
        return $object
    }
    return $hashTable
}
function ConvertfromJsonToHashtable{
    param([hashtable]$fromSender)
    $ErrorActionPreference = "Stop"
    if($null -eq $fromSender){
        $fromSender = @{}
    }
    $path = $fromSender.Path

    $content = $null
    try {
        if (Test-Path -Path $path) {
            $content = Get-Content -Path $path -ErrorAction Stop
        }
    } catch {
        $content = $null
    }

    if (-not $content) {
        return @{}
    }

    $jsonObj = ($content | ConvertFrom-Json)

    return ConvertObjectJsontoHashtable $jsonObj
}
function Invoke-UDFSQLCommand{
    param([hashtable]$fromSender)

    if($null -eq $fromSender){
        $fromSender = @{}
    }

    # default databasename
    if(-not($fromSender.ContainsKey('DatabaseName'))){
        $fromSender += @{DatabaseName = 'Master'}
    }

    # default processname
    if(-not($fromSender.ContainsKey('ProcessName'))){
        $fromSender += @{ProcessName = 'Invoke-UDFSQLCommand'}
    }
    $processname = $fromSender.ProcessName
    # 
    if(-not($fromSender.ContainsKey('TestConnection'))){
        $fromSender.Add('TestConnection',$false)
    }
    $testConnection = $fromSender.TestConnection

    if($testConnection){
        $query = "select [TestConnection] = 1 "
    }else{
        $query = ("{0}" -f $fromSender.Query)
    }

    # need username and password for sql auth
    if(($fromSender.ContainsKey("Username")) -and ($fromSender.ContainsKey("Password"))){
        $authType = "SQL"
    }else{
        $authType = "Windows"
    }

    # default databasename
    if(-not($fromSender.ContainsKey('ConnectionTimeout'))){
        $fromSender.Add("ConnectionTimeout",15)
    }
    $connectionTimeOut = $fromSender.ConnectionTimeout
    $sqlconnectionstring = switch($authType){
        "SQL"{
             "
                server              = $($fromSender.InstanceName);
                database            = $($fromSender.DatabaseName);
                user id             = $($fromSender.UserName);
                password            = $($fromSender.Password);
                application name    = $processname;
                connect timeout     = $($connectionTimeOut);
            "
        }
        "Windows"{
            "
                server              = $($fromSender.InstanceName);
                database            = $($fromSender.DatabaseName);
                trusted_connection  = true;
                application name    = $processname;
                connect timeout     = $($connectionTimeOut);
            "
        }
    }

    $sqlconnection                  = new-object system.data.sqlclient.sqlconnection
    $sqlconnection.connectionstring = $sqlconnectionstring

    try{
        $sqlconnection.open()
    }catch{
        return $Error[0]
    }
    
    $sqlcommand                     = new-object system.data.sqlclient.sqlcommand
    $sqlcommand.connection          = $sqlconnection
    $sqlcommand.commandtext         = $query

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
function ListSQLConnection{
    # context > servers connections
    return (Context).SQLConnections
}
function RemoveSQLConnection{
    Param([psobject]$fromSender)

    if($null -eq $fromSender){
        $fromSender = @()
    } 

    $connections = $fromSender
    foreach($connection in $connections){
        $connection.ConnectionObject.close()
        $connection.ConnectionObject.dispose()
        $global:connections  =   $global:connections| Where-Object { $_.ConnectionHash -ne $connection.ConnectionHash}
    }
}
function NewSessions{
	throw "Not implemented yet"
}
function CreateSqlConnection{
    param([hashtable]$fromSender)


    if($null -eq $fromSender){
        $fromSender = @{}
    }

    if($fromSender.ContainsKey('Preferences')){
        $context = Context $fromSender.Preferences
    }else{
        $context = Context
    }
    $preferences = $context.Preferences
    #$messages = $preferences.Messages
    $func = @{
        Name = $MyInvocation.MyCommand.Name
        MainParams = @{
            Mandatory = @("Instance")
            Optional = @{}
        }
        SubParams = @{
            Mandatory = @(
                "HostName"
                "InstanceName"
                )
            Optional = @{
                DatabaseName = "Master"
                ProcessName = "unknown"
                ConnectionTimeout = 3
            }
        }
    }
    
    $connectionPoolID = (((new-guid).guid) -split "-")[-1]
    $connectionID = 0
    $instances = $fromSender.Instance
    foreach($instance in $Instances){

        $msg = @{
            Preferences =  $context
            Message = @{
                Text = "Parsing '{0}'" -f $instance.InstanceName
                From = $($func.Name)
                Type = "Development"
            }
        }
        Message $msg

        $missingMandatoryParamsList = @()
        $isMissingMandatory = $false
        foreach($mandatoryParam in $func.SubParams.Mandatory){
            if(@($instance.keys) -notcontains $mandatoryParam){
                $missingMandatoryParamsList += $mandatoryParam
                $isMissingMandatory = $true
            }
        }
        
        if($isMissingMandatory){
            $msg = @{
                Preferences =  $context
                Message = @{
                    Text = "Missing mandatory parameter(s): '{0}'" -f ($missingMandatoryParamsList -join ', ')
                    From = $($func.Name)
                    Type = "Warning"
                }
            }
            Message $msg
        }else{
            foreach($optionalParam in $func.SubParams.Optional.keys){
                if(@($instance.keys) -notcontains $mandatoryParam){
                    $instance.Add($optionalParam,($func.SubParams.Optional.$optionalParam))
                }
            }
            $hostName = $instance.HostName
            $instanceName = $instance.InstanceName
            $databaseName = $instance.DatabaseName
            $processName = $instance.ProcessName
            $connectionTimeOut = $instance.ConnectionTimeOut
            $port = $instance.Port
            

            $hasUserName = $instance.ContainsKey('UserName') -and ($instance.UserName -ne $null -and $instance.UserName -ne '')
            $hasPassword = $instance.ContainsKey('Password') -and ($instance.Password -ne $null -and $instance.Password -ne '')
            
            if ($hasUserName -and $hasPassword) {
                $authType = "SQL"
            }
            elseif (-not $hasUserName -and -not $hasPassword) {
                $authType = "Windows"
            }
            else {
                $msg = @{
                    Preferences =  $context
                    Message = @{
                        Text ="Invalid authentication configuration: you must provide *both* UserName and Password for SQL authentication, or *neither* for Windows authentication."
                        From = $($func.Name)
                        Type = "Warning"
                    }
                }
                Message $msg
            }

            $msg = @{
                Preferences =  $context
                Message = @{
                    Text = "Auth type being used '{0}'" -f $authType
                    From = $($func.Name)
                    Type = "Development"
                }
            }
            Message $msg

            if($instance.ContainsKey("Port")){
                $port = $instance.Port
    
                if($null -ne $port){
                    $serverName = "{0},{1}" -f $instanceName,$port
                }else{
                    $serverName = "{0}" -f $instanceName
                }
                
            }else{
                $serverName = $instanceName
            }

            $sqlconnectionstring = switch($authType){
                "SQL"{
                     "
                        server              = $($serverName);
                        database            = $($databaseName);
                        user id             = $($instance.UserName);
                        password            = $($instance.Password);
                        application name    = $processname;
                        connect timeout     = $($connectionTimeOut);
                    "
                }
                "Windows"{
                    "
                        server              = $($serverName);
                        database            = $($databaseName);
                        trusted_connection  = true;
                        application name    = $processname;
                        connect timeout     = $($connectionTimeOut);
                    "
                }
            }

            $sqlconnection = new-object system.data.sqlclient.sqlconnection
            $sqlconnection.connectionstring = $sqlconnectionstring

            try{
                $sqlconnection.open()
            }catch{
                return $error[0]
            }
            $msg = @{
                Message = @{
                    Text = "This is a test"
                }
            }
            Message  $msg

            $connectionHash =  HashString ("{0}{1}{2}"-f $hostName,$InstanceName,$processName)

            if($null -eq (ListSQLConnection | where-object {$_.ConnectionHash -eq $connectionHash })){
                $global:connections += $sqlconnection | select-object @(
                    @{Name = "HostName";Expression = {$hostName}},
                    @{Name = "InstanceName";Expression = {$instanceName}},
                    "Database",
                    @{Name = "Port";Expression = {$port}},
                    @{Name = "ProcessName";Expression = {$processName}},
                    @{Name = "ConnectionPoolID";Expression = {$connectionPoolID}},
                    @{Name = "ConnectionID";Expression = {$connectionID}},
                    @{Name = "ConnectionHash";Expression = {$connectionHash}},
                    @{Name = "ConnectionObject";Expression = {$sqlconnection}}
                )
    
                $connectionID  =   $global:connectionID  + 1
            }else{
                RemoveSQLConnection ($global:connections)
                $global:connections += $sqlconnection | select-object @(
                    @{Name = "HostName";Expression = {$hostName}},
                    @{Name = "InstanceName";Expression = {$instanceName}},
                    "Database",
                    @{Name = "Port";Expression = {$port}},
                    @{Name = "ProcessName";Expression = {$processName}},
                    @{Name = "ConnectionPoolID";Expression = {$connectionPoolID}},
                    @{Name = "ConnectionID";Expression = {$connectionID}},
                    @{Name = "ConnectionHash";Expression = {$connectionHash}},
                    @{Name = "ConnectionObject";Expression = {$sqlconnection}}
                )
            }
        }
    }
}
function HashString{
    param (
        [string]$InputString,
        [string]$Algorithm = "SHA256"  # SHA1, SHA256, SHA384, SHA512, MD5
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $hashBytes = $hashAlgorithm.ComputeHash($bytes)
    -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
}
function PSUtilConfig{
    return $global:config
}
function SetUpRootDirectory{
    param([hashtable]$fromSender)

    $utilityVars = _UtilityVars
    $for = $fromSender.For
    $myHome = $utilityVars.Home
    $path = join-path $myHome $for

    if(-not(test-path -path $path)){
        
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "creating root directory '{0}'" -f $path
        }
        new-item -path $path -itemtype "directory" | out-null
    }else{
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "root directory '{0}' already exists" -f $path
        }
    }
}
function SetupStoresDirectory{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $for = $fromSender.For

    $path = join-path $myHome (join-path $for 'Stores')
    if(-not(test-path -path $path)){
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "creating stores directory '{0}'" -f $path
        }
        new-item -path $path -itemtype "directory" | out-null
    }else{
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "stores directory '{0}' already exists" -f $path
        }
    }
}
function SetUpSchemasDirectory{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $for = $fromSender.For

    $path = join-path $myHome (join-path $for 'Schemas')
    if(-not(test-path -path $path)){
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "creating schema directory '{0}'" -f $path
        }
        new-item -path $path -itemtype "directory" | out-null
    }else{
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "schemas directory '{0}' already exists" -f $path
        }
    }
}
function GetStores{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $path = join-path $myHome (join-path $in 'Stores')

    $stores = get-childitem -path $path
    $storesTable = @{}
    if($stores.count -ne 0){
        foreach($item in $stores){
            $storesTable += @{$item.BaseName = @{
                Path = $item.FullName
            }}
        }
    }
    return $storesTable
}
function FromStore{
    param([hashtable]$fromSender)

    $in = $fromSender.In
    $stores = GetStores @{In = $in}
    $storesList = $stores.keys
    
    $myStores = $fromSender.Stores

    $dataTable = @{}
    foreach($store in $myStores){
        $name = $store.Name
        if($storesList -contains $name){
            $path = $stores.$name.Path
            $content = get-content -path $path
            $object = $content | convertfrom-csv
            $dataTable.Add("$name",$object)
        }
    }
    return $dataTable
}
function NewStore{
    param([hashtable]$fromSender)

    $ErrorActionPreference = (PSUtilConfig).Preferences.ErrorAction


    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $stores = $fromSender.Stores
    $storesPath = join-path $myHome (join-path $in 'Stores')

    foreach($store in $stores){
        $name = $store.Name

        # is a schema being referenced?
        if($store.ContainsKey('UseSchema')){
            $useSchema = $true
            Message2 @{
                Type = "Informational"
                From = ($MyInvocation.MyCommand.name)
                Text = "referencing a schema"
            }
        }else{
            $useSchema = $false
            Message2 @{
                Type = "Informational"
                From = ($MyInvocation.MyCommand.name)
                Text = "not referencing a schema"
            }
        }

        if($useSchema){
            $from = $store.UseSchema.from
            $schemaName = $store.UseSchema.Name
            $fromSchemas = GetSchemas @{
                In = $in
                Name = $from
            }

            # does the schema being referenced exist?
            if($fromSchemas.ContainsKey($schemaName)){
                Message2 @{
                    Type = "success"
                    From = ($MyInvocation.MyCommand.name)
                    Text = "schema '{0}' being referenced for store '{1}' exist" -f $schemaName, $name
                }

                if(-not($fromSchemas.$schemaName.ContainsKey("LinkedStores"))){
                    $fromSchemas.$schemaName.Add("LinkedStores",@())
                }
                $linkedStored = @($fromSchemas.$schemaName.LinkedStores)

                if($linkedStored -notcontains (join-path  $storesPath $name)){
                    $linkedStored += (join-path  $storesPath $name)
                    $fromSchemas.$schemaName.LinkedStores =  $linkedStored

                    Message2 @{
                        Type = "Informational"
                        From = ($MyInvocation.MyCommand.name)
                        Text = "adding '{0}' to schema '{1}'" -f (join-path  $storesPath $name),$schemaName
                    }
                }
                if($fromSchemas.$schemaName.CanBeDeleted){
                    Message2 @{
                        Type = "Informational"
                        From = ($MyInvocation.MyCommand.name)
                        Text = "schema '{0}' cannot be deleted now" -f $schemaName
                    }
                    $fromSchemas.$schemaName.CanBeDeleted =  $false
                }
            }else{
                $msg = ("the schema being referenced: '{)}', does not exist") -f $schemaName
                write-error $msg
            }

            $schemajson =  $fromSchemas | convertto-json -depth 4
            $path = join-path (join-path $myHome (join-path $in 'Schemas')) $from
    
             Message2 @{
                 Type = "Informational"
                 From = ($MyInvocation.MyCommand.name)
                 Text = "schema '{0}' updated" -f $path
             }
             set-content -path $path -value $schemajson | out-null

        }else{
            Message2 @{
                Type = "warning"
                From = ($MyInvocation.MyCommand.name)
                Text = "store '{0}' is being created without being linked to a schema" -f $sche
            }
        }



        # path to store file
        $path = join-path $storesPath $name
        if(-not(Test-Path -path $path)){

            try{
                new-item -path $path -itemType 'File' | out-null
                Message2 @{
                    Type = "success"
                    From = ($MyInvocation.MyCommand.name)
                    Text = "store '{0}' in '{1} created successfully" -f $name, $path
                }
            }catch{
                return $error[0]
            }
            
        }else{
            Message2 @{
                Type = "Informational"
                From = ($MyInvocation.MyCommand.name)
                Text = "store '{0}' already exists in '{1}" -f $name, $in
            }
        }
    }
}
function RemoveStore{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $for = $fromSender.For
    $stores = $fromSender.Stores
    $storesPath = join-path $myHome (join-path $for 'Stores')

    foreach($store in $stores){
        $name = $store.Name
        $path = join-path $storesPath $name
        $path = $path

        $checks = @{
            fileExists = $false
            hasSchemaReference = $false
        }
        # if the stores exists
        if(Test-Path -path $path){
            $checks.fileExists = $true
           # Remove-item -path $path | out-null
        }

        # if theres a schema directory look in it
        if(test-path (join-path $myHome (join-path $for 'Schemas'))){
            (GetSchemas @{In = $for; Name = $schema_file})
        }
        $path
    }
}
# schema creation and management functions
function CreateSchemasFile{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $name = $fromSender.Name
    $path = join-path (join-path $myHome (join-path $in 'Schemas')) $name

    if(-not (test-path -path $path)){
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "creating schema file '{0}'" -f $path
        }
        new-item -path $path -itemtype "file" | out-null

        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "schema file '{0}' initalized" -f $path
        }
        set-content -path $path -value "{}" | out-null
    }else{
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "schema file '{0}' already exists" -f $path
        }
    }
}
function GetSchemas{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $name = $fromSender.Name
    $path = join-path (join-path $myHome (join-path $in 'Schemas')) $name
    if(test-path $path){
        Message2 @{
            Type = "Informational"
            From = ($MyInvocation.MyCommand.name)
            Text = "schema: '{0}' from: '{1}'" -f $name, $in
        }
        $schema = ConvertfromJsonToHashtable @{Path = $path}

        Message2 @{
            Type = "Informational"
            From = ($MyInvocation.MyCommand.name)
            Text = "contains a total of '{0}' schemas" -f $schema.count
        }
        return $schema
    }else{
        Message2 @{
            Type = "Informational"
            From = ($MyInvocation.MyCommand.name)
            Text = "schema '{0}' does not exist in '{1}', run CreateSchemaFile first" -f $name, $in
        }
    }


}
function RemoveSchemasFile{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $name = $fromSender.Name
    $path = join-path (join-path $myHome (join-path $in 'Schemas')) $name
    if(test-path $path){
        Message2 @{
            Type = "informational"
            From = ($MyInvocation.MyCommand.Name)
            Text = "removing schema '{0}'" -f $path
        }
        remove-item $path -force | out-null
    }
}
function CreateSchema{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $name = $fromSender.Name
    $path = join-path (join-path $myHome (join-path $in 'Schemas')) $name

    # create the schema file if it doesnt already exists
    if(-not(test-path -path $path)){
        CreateSchemasFile @{
            In = $in
            Name = $name
        }
    }

    $name = $fromSender.store.Name
    $schema = $fromSender.store.schema

    # check that no property is missing
    $mandatory = @(
        "DataType"
        "Default"
        "Null"
    )
    $schemaCopy = @{$name = [ordered]@{Properties = @{};Index = @{};CanBeDeleted = $true}}
    foreach ($key in $Schema.properties.Keys) {
        $prop = $Schema.Properties[$key]

        $missing = $false
        $missingProperties = @()
        foreach($mandatoryItem in $mandatory){
            if(-not($prop.ContainsKey($mandatoryItem))){
                $missing = $true
                $missingList += $mandatoryItem
            }
        }

        if($missing){
            Write-Error ($missingList -join " ")
        }

        $dataType = switch($prop.DataType){
            {$_.Name -eq 'string'}{
                'string'
            }
            {$_.Name -eq 'int32'}{
                'int'
            }
            {$_.Name -eq 'datetime'}{
                'datetime'
            }
        }
        $schemaCopy.$name.Properties += @{
            $key = @{
                Type = $dataType
                Default = $prop.Default
                Null = $prop.Null
            }

        }
       # $schemaCopy | convertto-json -depth 3
    }

    # index is optional, so it can be omitted
    if($schema.ContainsKey('Index')){
        $index = $schema.Index
        
        $mandatory = @(
            "Name"
            "Type"
            "On"
        )

        $missingList = @()
        $isMissingMandatory = $false
        foreach($mandatoryItem in $mandatory){
            if(-not($index.ContainsKey($mandatoryItem))){
                $isMissingMandatory = $true
                $missingList += $mandatoryItem
            }
        }
        if($isMissingMandatory){
            Write-Error ($missingList -join " ")
        }
        $schemaCopy.$name.Index =  $index
    }else{
        $schemaCopy.$name.Index = [ordered]@{
            Name = ''
            Type = ''
            On = ''
        }
    }

    # read the contents of the schema files
    $fromSchemas = GetSchemas @{
        In = $in
        Name = $fromSender.Name
    }

    # check to make sure that the current schema doesnt already exists in the schema file
    if(-not($fromSchemas.ContainsKey($name))){
        Message2 @{
            Type = "Informational"
            From = ($MyInvocation.MyCommand.name)
            Text = "current schema '{0}' does not exists, adding new schema" -f $name
        }
        $fromSchemas += $schemaCopy

        $schemajson = $fromSchemas | convertto-json -depth 4

        Message2 @{
            Type = "Informational"
            From = ($MyInvocation.MyCommand.name)
            Text = "schema '{0}' updated" -f $name
        }
        set-content -path $path -value $schemajson | out-null
    }else{
        Message2 @{
            Type = "Warning"
            From = ($MyInvocation.MyCommand.name)
            Text = "there is already a schema named '{0}'" -f $name
        }

        Message2 @{
            Type = "Warning"
            From = ($MyInvocation.MyCommand.name)
            Text = "schema '{0}' not updated" -f $name
        }
    }
}
function DeleteSchema{
    param([hashtable]$fromSender)

    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $From = $fromSender.from
    $path = join-path (join-path $myHome (join-path $in 'Schemas')) $from

    # create the schema file if it doesnt already exists
    if(-not(test-path -path $path)){
        Message2 @{
            Type = "Warning"
            From = ($MyInvocation.MyCommand.name)
            Text = "schema '{0}' does not exist in '{1}', delete operation termindated" -f $from, $in
        }
    }else{
        $fromSchemas = GetSchemas @{
            In = $in
            Name = $from
        }

        $name = $fromSender.Name
        if($fromSchemas.ContainsKey($name)){
            if($fromSchemas.$name.CanBeDeleted){
                Message2 @{
                    Type = "Informational"
                    From = ($MyInvocation.MyCommand.name)
                    Text = "schema named '{0}' in '{1}' from '{2}', can be deleted" -f $name, $in,$from
                }

                Message2 @{
                    Type = "Informational"
                    From = ($MyInvocation.MyCommand.name)
                    Text = "schema named '{0}' exists in '{1}' from '{2}', removing it" -f $name, $in,$from
                }
                $fromSchemas.remove($name)
            }else{
                Message2 @{
                    Type = "Informational"
                    From = ($MyInvocation.MyCommand.name)
                    Text = "schema named '{0}' exists in '{1}' from '{2}', removing it" -f $name, $in,$from
                }
            }
            
            if($fromSchemas.count -eq 0){
                $schemajson = '{}'
            }else{
                $schemajson = $fromSchemas | convertto-json -depth 4
            }
            set-content -path $path -value $schemajson

            Message2 @{
                Type = "Success"
                From = ($MyInvocation.MyCommand.name)
                Text = "schema named '{0}' exists in '{1}' from '{2}', removed" -f $name, $in,$from
            }
        }else{
            Message2 @{
                Type = "Warning"
                From = ($MyInvocation.MyCommand.name)
                Text = "schema named '{0}' does not exists in '{1}' from '{2}'" -f $name, $in,$from
            }
        }
    }


}
function GetLinkStores{
    param([hashtable]$fromSender)
    $myHome = (_UtilityVars).Home
    $in = $fromSender.In
    $From = $fromSender.from
    $name = $fromSender.Name

    $schema = GetSchemas @{
        In = $in
        Name = $from
    }
    if($schema.ContainsKey($name)){
        if($schema.$name.ContainsKey("LinkedStores")){
            $schema.$name.LinkedStores
        }else{
            Message2 @{
                Type = "warning"
                From = ($MyInvocation.MyCommand.name)
                Text = "schema '{0}' does not contain a linkedStores property. Create a store with NewStores, use the UseSchema parameter." -f $name
            }
        }
    }else{
        Message2 @{
            Type = "Warning"
            From = ($MyInvocation.MyCommand.name)
            Text = "there is no schema in '{0}' from '{1}' named '{2} " -f $in, $from, $name
        }
    }
}

# insert into stores 
function InsertToStore{

}