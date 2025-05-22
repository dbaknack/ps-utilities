$utilities = [setUp]::new(@{For = 'ps-utilities'})

# create some stores
$utilities.NewStore(@{
    Stores = @(
        @{Name = 'Config'}
    )
})

# list out the stores
$script:utilities.GetStores()
$script:utilities.RemoveStore(@{Store = @{Name = "Servers"}})
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