Describe 'ConvertfromJsonToHashable' {
    It 'for testing purposes, this path should exist' {
        $fromSender = @{Path = "./test/test.json"}
        $result = test-path -path $fromSender.Path
        $result | Should -Be $true
    }
    It 'results should be a hashtable' {
        $fromSender = @{Path = "./test/test.json"}
        $result = ConvertfromJsonToHashtable $fromSender
        $result | Should -BeOfType 'hashtable'
    }
}