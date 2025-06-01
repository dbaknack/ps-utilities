import-module ./ps-utilities

# TODO: does not export when loaded as a module
$utilities = [setUp]::new(@{For = 'ps-utilities'})


# add a server
$utilities.InsertTo(@{
    Stores = @(
        @{
            Name = "Servers"
            Items = @(
                [pscustomobject]@{
                    DomainName  = ".local"
                    ServerName  = "Macbook"
                    IP          = 127.0.0.1
                    Tag         = "local-dev"
                }
            )
        }
    )
})
# create some stores
$utilities.NewStore(@{
    Stores = @(
        @{Name = 'Config'}
    )
})

remove-module ps-utilities
# list out the stores
$global:utilities.GetStores()
$global:utilities.RemoveStore(@{Store = @{Name = "Servers"}})
# insert into stores
$utilities.InsertTo(@{
    Stores = @(
        @{
            Name = "Test2"
            Items = @(
                [pscustomobject]@{Testname = 1;something = "this"}
                [pscustomobject]@{Testname = 2;something = "3"}
            )
        }
        @{
            Name = "Test3"
            Items = @(
                [pscustomobject]@{Testname = 1;something = "this"}
                [pscustomobject]@{Testname = 2;something = "3"}
            )
        }
    )
})

# select from stores
$data = ($utilities.GetFrom(@{Stores = @{Name = "Test3"}}))
$data."Test3"

# remote a data store

$utilities.RemoveStore((@{Stores = @{Name = "Servers"}}))


# add a server to store

GetServers