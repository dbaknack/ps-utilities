creating a schema


```powershell
CreateSchema  @{
    In = "ps-utilities"
    Name = "Schemas.json"
    Store = @{
        Name = "Servers"
        Schema = @{
            Properties      = [ordered]@{
                ServerID    = @{DataType = [int];       Default = @{Seed =1;Increment = 1}; Null = $false}
                Enclave     = @{DataType = [string];    Default = "dev";                    Null = $false}
                DomainName  = @{DataType = [string];    Default = ".local";                 Null = $false}
                HostName    = @{DataType = [string];    Default = $null;                    Null = $false}
            }
            Index = @{
                Name = "ix_server"
                Type = "Composite"
                On = @(
                    "Enclave"
                    "DomainName"
                    "Hostname"
                )
            }
        }
    }
}
```