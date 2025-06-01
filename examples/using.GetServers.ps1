import-module ./ps-utilities

# store references to servers
StashServer @{
    Servers = @(
     # @{DomainName = "attlocal.net";Name = "alexhernand2c42"; IP = "192.168.1.183"}
        @{DomainName = "lab.com";Name ="sql01";IP = "10.0.0.165";Tag = "remote-dev"}
        @{DomainName = "lab.com";Name ="sql02";IP = "10.0.0.169";Tag = "remote-dev"}
        @{DomainName = "lab.com";Name ="win16-vdi01";IP = "10.0.0.168";Tag = "dev-vdi"}
        @{DomainName = ".local";Name ="alexhernand2c42";IP = "127.0.0.1";Tag = "local-dev"}
    )
}

# select form the stash
GetServers | ft -a


# remove if needed
RemoveServer  @{
    Where       = "Name"
    Operator    = "-eq"
    Property    = "macbook"
}

$sqlServers = GetServers | where-object {$_.Name -like "sql*"}
$sqlServers

remove-module ps-utilities


remove-item (Context).Stores.servers.Path