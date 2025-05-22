import-module ./ps-utilities

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
Invoke-UDFSQLCommand  @{
    InstanceName    = "macbook"
    DatabaseName    = "master"
    UserName        = "sa"
    Password        = "P@55word"
    Query           = "select @@version"
}

remove-module -name ps-utilities