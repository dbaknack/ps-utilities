import-module ./ps-utilities

remove-module ps-utilities

# use this to get the stores in the given directory basename
GetStores @{In = "ps-utilities"}

# use this to create a new store ifrom the given list of stores in the given directory basename
NewStore @{
    In = "ps-utilities"
    Stores = @(
        @{
            Name = "Servers"
            UseSchema = @{
                From = "Schemas.json"
                Name = "Servers"}
        }
    )
}

CreateSchemasFile @{
    In = 'ps-utilities'
    Name = "schemas.json"
}
RemoveSchemasFile @{
    In = 'ps-utilities'
    Name = "schemas.json"
}
# use this to get information from the given list of store names in the given directory basename
FromStore  @{
    In = "ps-utilities"
    Stores = @(
        @{Name = "Servers"}
    )
}

# get the schemas in the given root with from the given file name
GetSchemas @{
    In = "ps-utilities"
    Name = "Schemas.json"
}

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

# use this to create a new store from the given list of stores in the given directory basename
NewStore @{
    In = "ps-utilities"
    Stores = @(
        @{
            Name = "some-store"
            UseSchema = @{Name = "Servers2"}
        }
    )
}

DeleteSchema @{
    In = "ps-utilities"
    From = "Schemas.json"
    Name = "Servers2"
}

# given a schema, get the linkstores in the given root from the given file with the given name
GetLinkStores @{
    In = "ps-utilities"
    From = "Schemas.json"
    Name = "Servers"
}

InsertToStore @{
    Name = "Servers"
    Items = @(
        [pscustomobject]@{}
    )
}

GetStores @{In ='ps-utilities'}

NewStore @{
    In = "ps-utilities"
    Stores = @(
        @{
            Name = "servers-dev"
            UseSchema = @{
                From = "Schemas.json"
                Name = "Servers"}
        }
    )
}


# define variables
$in = "ps-utilities"
$for = "ps-utilities"
$schema_file = "schemas.json"
$schema_name = "Servers"
$store_servers_prd = @{
    Name = "servers-tst"
    UseSchema = @{
        From = $schema_file
        Name = $schema_name
    }
}

# create store
NewStore @{In = $in; Stores = @($store_servers_prd)}

# view store
GetStores @{In = $in}

$schema = (GetSchemas @{In = $in; Name = $schema_file}).$schema_name
$schema.properties
$schema.Index
$schema.CanBeDeleted
$schema.LinkedStores


PSUtilConfig

$fromSender = @{
    For = "ps-utilities"
    UseSchema = @{
        From = "schemas.json"
        Name = "Servers"
    }
    Stores = @(
        @{Name = $store_servers_prd.Name}
    )
}