### how to create a new store

-   stores are used to store information to be later used
-   its recommended that store use a schema (see ./create-schema.md)


-   create a store that is using a schema to enforce integrity; in the following manner
    ``` powershell

    # defines parameters 
    $in = "ps-utilities"
    $store_servers_prd = @{
        Name = "servers-prd"
        UseSchema = @{
            From = "Schemas.json"
            Name = "Servers"
        }
    }
    
    # run create store command
    NewStore @{In = $in; Stores = @($store_servers_prd)}
    ```

-   validate that the store has been create
    ```powershell
        GetStores @{In = $in}
    ```