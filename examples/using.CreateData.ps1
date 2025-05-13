function MakeString {
    param([hashtable]$fromSender)

    if($null -eq $fromSender){
        $fromSender = @{}
    }
    if(-not($fromSender.ContainsKey('Length'))){
        $fromSender.Add('Length',10)
    }
    $length = $fromSender.Length
    
    if(-not($fromSender.ContainsKey('Limit'))){
        $fromSender.Add('Limit',10 + 1)
    }
    $limit = $fromsender.Limit
    
    if(-not($fromSender.ContainsKey('Randomize'))){
        $fromSender.Add('Randomize',$true)
    }
    $randomize = $fromsender.Randomize
    
    if(-not($fromSender.ContainsKey('FirstCharUppet'))){
        $fromSender.Add('FirstCharUppet',$false)
    }
    $firstCharUpper = $fromsender.FirstCharUppet
    
    if(-not($fromSender.ContainsKey('PadRightWith'))){
        $fromSender.Add('PadRightWith',$null)
    }
    $padrightWith = $fromSender.PadRightWith
    
    if(-not($fromSender.ContainsKey('PadLeftWith'))){
        $fromSender.Add('PadLeftWith',$null)
    }
    $padleftWith = $fromSender.PadLeftWith
    
    if(-not($fromSender.ContainsKey('IncludeNumbers'))){
        $fromSender.Add('IncludeNumbers',$false)
    }
    $includeNumbers = $fromSender.IncludeNumbers
    
    # definitions
    $string = ""
    $alphabetlower = 'a'..'z'
    $alphabetUpper = 'A'..'Z'
    $special = @('!','@','#','$','%','^','&','*','(',')','-','_','=','+','{','}','[',']','\','/','?','|')
    $numbers = 0..9
    
    switch($length){
        {$_ -ne 0 }{
            $startAt    = 0
            $endAt      = ($_ - 1 )
            break
        }
        {$_ -eq 0}{            
            $startAt = 0
            $endAt = get-random -min 1 -max (($Limit) + 1)
            break
        }
    
    }

    $array =  $startAt..$endAt 
    if($randomize){
        $array = $array | Get-Random -Count $array.Count
    }
    
    $stringList = @()
    for($i = 0;$i -lT ($array.count);$i++){
        $index = $array[$i]
        if($index -gt 26){
            $index = $index %26
        }
        #write-host "i: $i - index: $index"
        $stringList += $alphabetlower[$index]
    }

    if($includeNumbers){
       $index = get-random -min 1 -max ($stringList.count)

       $replaceThisChar = $stringList[$index]

        $newString = @()
        foreach($i in $stringList){
            if($i  -eq $replaceThisChar){
                $newString += get-random -min 0 -max 9
            }else{
                $newString += $i
            }
        }
        $stringList = $newString
    }
    $string = $stringList -join ""
    if($firstCharUpper){
        $string = $string.Substring(0,1).ToUpper() + $string.Substring(1)
    }
    $padleftWith+$string+$padrightWith
    
}

# list of parameters
# TODO: still need to include special characters
MakeString @{
    Length          = 0         # by default this is 10
    Limit           = 13        # by default this is 11
    Randomize       = $true   # by default this is true, when false, the string is in order
    FirstCharUppet  = $true     # by default this is false, makes the first char not upper
    PadRightWith    = "@gmail.com"       # by default this is $null
    PadLeftWith     = (MakeString @{PadRightWith = "."})  # by default this is $null
    IncludeNumbers  = $true     # by default this is false
    includeSpecial = $true      # by default this is false
}


# use 0 as the length to make a random length, here its of a random length witha limit of 30
MakeString @{length = 0; limit = 30}

# default limit when using random length is 11
MakeString @{Length = 0}

# default length is 10
MakeString

# randomize is set to true by default, when false, string is in-order
MakeString @{randomize = $false}

# get the alphabet this way
MakeString @{Length = 26;randomize = $false}

# pad lef and righjt with some string
MakeString @{PadLeftWith = "hello- "; PadRightWith = " -world"}

# this is an interesting use case
MakeString @{
    PadLeftWith = MakeString @{PadLeftWith = "hello- "; PadRightWith = " -world"}
    PadRightWith = MakeString @{PadLeftWith = "hello- "; PadRightWith = " -world"}
}