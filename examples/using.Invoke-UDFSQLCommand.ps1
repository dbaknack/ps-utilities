Invoke-UDFSQLCommand @{
    InstanceName    = "SQL01\DEV01"
    DatabaseName    = "master"
    Query           = "select * from sys.databases"
}
Invoke-UDFSQLCommand @{
    InstanceName    = "macbook"
    DatabaseName    = "master"
    Query           = "select * from sys.databases"
}