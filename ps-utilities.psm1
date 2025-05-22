class setUp {
    [string]$Root = $HOME
    [String]$For

    setUp([hashtable]$fromSender){
        $this.setUpRootDirectory($fromSender.For)
        $this.setUpStoresDirectory()
    }
    [void] setUpRootDirectory([string]$FromSender){
        $path = join-path $this.Root $FromSender
        if(-not(test-path -path $path)){
            new-item -path $path -itemtype "directory" | out-null
        }
        $this.For = $FromSender
    }
    [void] setUpStoresDirectory(){
        $path = join-path $this.Root (join-path $this.For 'Stores')
        if(-not(test-path -path $path)){
            new-item -path $path -itemtype "directory" | out-null
        }
    }
    [hashtable] GetStores(){
        $path = join-path $this.Root (join-path $this.For 'Stores')
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
    [void] NewStore([hashtable]$fromSender){
        $stores = $fromSender.Stores
        $storesPath = join-path $this.Root (join-path $this.For 'Stores')

        foreach($store in $stores){
            $path = join-path $storesPath $store.Name
            $path = $path
            if(-not(Test-Path -path $path)){
                new-item -path $path -itemType 'File' | out-null
            }
        }
    }
    [void] RemoveStore([hashtable]$fromSender){
        $stores = $fromSender.Stores
        $storesPath = join-path $this.Root (join-path $this.For 'Stores')

        foreach($store in $stores){
            $path = join-path $storesPath $store.Name
            $path = $path
            if(Test-Path -path $path){
                Remove-item -path $path | out-null
            }
        }
    }
    [void] InsertTo([hashtable]$fromSender){
        $stores = $this.GetStores()
        $storesList = $stores.keys
        
        $myStores = $fromSender.Stores

        foreach($store in $myStores){
            if($storesList -contains $store.Name){
                $name = $store.Name
                $path = $stores.$name.Path
                $content = get-content -path $path
                $object = $content | convertfrom-csv
                
                $csv = ($object + $store.Items) | convertto-csv
                set-content -path $path -value $csv | out-null
            }
        }
    }
    [hashtable] GetFrom([hashtable]$fromSender){
        $stores = $this.GetStores()
        $storesList = $stores.keys
        
        $myStores = $fromSender.Stores

        $dataTable = @{}
        foreach($store in $myStores){
            if($storesList -contains $store.Name){
                $name = $store.Name
                $path = $stores.$name.Path
                $content = get-content -path $path
                $object = $content | convertfrom-csv
                $dataTable.Add("$name",$object)
            }
        }
        return $dataTable
    }
}
$script:utilities = [setUp]::new(@{For = 'ps-utilities'})

function GetServers{
    $store = "Servers"
    ($utilities.GetFrom(@{Stores = @{Name = $store}})).$store
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

        if($entryValid){
            if($data.count -eq 0){
                $duplicateExists = $false
            }else{
                if($null -eq ($data | where-object {$_.DomainName -eq $domainName -and $_.Name -eq $name -and $_.IP -eq $ip})){
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
    $insert = $data | select-object DomainName,Name,IP,@{Name = "GUID";Expression = {(New-Guid).guid}}
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

    # create 
    $script:utilities.NewStore(@{
        Stores = @(
            @{Name = 'Config'}
        )
    })
    
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
        SQLConnections = $global:connections
        Stores = $script:utilities.GetStores()
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
function NewSQLConnection{
    param([hashtable]$fromSender)

    if($null -eq $fromSender){
        $fromSender = @{}
    }

    if(-not($fromSender.ContainsKey('Instances'))){
        $fromSender.Add('Instances',@())
    }  

    $Instances = $fromSender.Instances
    
    $connectionPoolID = (((new-guid).guid) -split "-")[-1]
    $connectionID = 0
    if($null -eq ($global:connections)){
        $global:connections = @()
    }
    foreach($instance in $Instances){
        if(-not($instance.ContainsKey('HostName'))){
            $instance.Add("HostName",$null)
        }
        $hostName = $instance.HostName

        if(-not($instance.ContainsKey('InstanceName'))){
            $instance.Add("InstanceName",'master')
        }
        $instanceName = $instance.InstanceName

        if(-not($instance.ContainsKey('DatabaseName'))){
            $instance.Add("DatabaseName",'Master')
        }
        $databaseName = $instance.DatabaseName

        if(-not($instance.ContainsKey('ProcessName'))){
            $instance.Add("ProcessName",("{0}-{1}-{2}"  -f "NewSQLConnection",$connectionPoolID,$connectionID))
        }
        $processName = ("{0}-{1}-{2}" -f $instance.ProcessName,$connectionPoolID,$connectionID)

        if(-not($instance.ContainsKey('ConnectionTimeout'))){
            $instance.Add("ConnectionTimeout",2)
        }
        $connectionTimeOut = $instance.ConnectionTimeout

        if(($instance.ContainsKey("Username")) -and ($instance.ContainsKey("Password"))){
            $authType = "SQL"
        }else{
            $authType = "Windows"
        }

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
        $sqlconnection.open()
        $global:connections += $sqlconnection | select-object @(
            @{Name = "HostName";Expression = {$hostName}}
            @{Name = "InstanceName";Expression = {$instanceName}}
            "Database"
            "State"
            "ClientConnectionId"
            @{Name = "Port";Expression = {$port}}
            @{Name = "ProcessName";Expression = {$processName}},
            @{Name = "ConnectionObject";Expression = {$sqlconnection}}
        )
        $connectionID  =   $global:connectionID  + 1
    }
    (Context).SQLConnections += $connections
}
function GetSQLConnection{
    return (Context).SQLConnections
}
function NewSessions{
	throw "Not implemented yet"
}