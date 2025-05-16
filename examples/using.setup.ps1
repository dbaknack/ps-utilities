$utilities = [setUp]::new(@{For = 'ps-utilities'})

$stores = $utilities.GetStores()
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

($utilities.GetFrom(@{Stores = @{Name = "Test3"}}))
$utilities.NewStore(@{
    Stores = @(
        @{Name = 'Test'}
        @{Name = 'Test3'}
    )
})
$utilities.NewStore(@{
    Stores = @(
        @{Name = 'Test'}
        @{Name = 'Test2'}
    )
})
