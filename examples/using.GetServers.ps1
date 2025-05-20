import-module ./ps-utilities

# store references to servers
StashServer @{
    Servers = @(
        @{DomainName = "attlocal.net";Name = "alexhernand2c42"; IP = "192.168.1.183"}
        @{DomainName = "lab.com";Name ="sql01";IP = "10.0.0.165"}
        @{DomainName = "lab.com";Name ="sql02";IP = "10.0.0.169"}
        @{DomainName = "lab.com";Name ="win16-vdi01";IP = "10.0.0.168"}
    )
}

# select form the stash
GetServers

# remove if needed
RemoveServer  @{
    Where       = "Name"
    Operator    = "-like"
    Property    = "win16-vdi01"
}

$sqlServers = GetServers | where-object {$_.Name -like "sql*"}
$sqlServers