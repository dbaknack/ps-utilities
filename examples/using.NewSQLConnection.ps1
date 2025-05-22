import-module ./ps-utilities

NewSQLConnection @{
    Instances = @(
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "some-processes"
            InstanceName = "macbook"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
    )
}

NewSQLConnection @{
    Instances = @(
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "first-process"
            InstanceName = "macbook"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
        @{
            HostName = "macbook"
            Port = 1433
            ProcessName = "some-other-process"
            InstanceName = "macbook"
            DatabaseName = "master"
            UserName = "sa"
            Password = "P@55word"
        }
    )
}

remove-module -name ps-utilities