$servers = GetServers | where-object {$_.Name -eq "alexhernand2c42"}

new-pssession -hostname 'alexhernand2c42' -UserName "alexhernandez"


ssh alexhernand2c42@alexhernandez