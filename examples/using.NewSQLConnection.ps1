import-module ./ps-utilities

# creating a single connection a sql server instance using an ip
CreateSqlConnection @{
    Instance = @(
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "first-process"
            InstanceName = "192.0.0.2"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
    )
}

CreateSqlConnection @{
    Instance = @(
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "first-process"
            InstanceName = "macbook.local"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
    )
}

CreateSqlConnection  @{
    Instance = @(
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "first-process"
            InstanceName = "192.0.0.2"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "first-process"
            InstanceName = "macbook.local"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
    )

    Preferences = @{
        Messages = @{
            Enabled = $true
            Development = @{
                Enabled = $true
            }
        }
    }
}

$sqlConnection = $global:connections
RemoveSQLConnection $sqlConnection
remove-module -name ps-utilities

$global:connections = $null

RemoveSQLConnection (ListSQLConnection)

ListSQLConnection | ft -a




$server = GetServers | where-object {$_.IP -eq '127.0.0.1'}


CreateSqlConnection @{
    Instance = @(
        @{
            HostName        = ($server.ip)
            Port            = 1433
            ProcessName     = "test-connection"
            InstanceName    = ($server.ip)
            DatabaseName    = "master"
            UserName        = "sa"
            Password        = "P@55word"
        }
    )
}