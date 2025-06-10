function ExtractFromManual{
    param([hashtable]$fromSender)
    $ErrorActionPreference = "Stop"

    $manuals = $fromSender.Manual
    $manuals | foreach-object {
        $path = $_.Path
        $manualExist = test-path -path $path

        if($manualExist){
            [xml]$xml = Get-Content -path $path
            $extracted = @{}
            $extracted.add("Dc",$xml.Benhmark.dc)
            $extracted.add("Xsi",$xml.Benchmark.xsi)
            $extracted.add("Cpe",$xml.Benchmark.cpe)
            $extracted.add("Xhtml",$xml.Benchmark.xhtml)
            $extracted.add("Dsig",$xml.Benchmark.dsig)  
            $extracted.add("SchemaLocation",$xml.Benchmark.schemaLocation)  
            $extracted.add("Id",$xml.Benchmark.id)  
            $extracted.add("Lang",$xml.Benchmark.lang)  
            $extracted.add("Xmlns",$xml.Benchmark.xmlns)      
            $extracted.add("Date",$xml.Benchmark.status.date)  
            $extracted.add("StatusText",$xml.Benchmark.status.'#text') 
            $extracted.add("Title",$xml.Benchmark.title) 
            $extracted.add("NoticeID",$xml.Benchmark.notice.id) 
            $extracted.add("NoticeLang",$xml.Benchmark.notice.lang) 
            $extracted.add("FrontMatterLang",$xml.Benchmark.'front-matter'.lang) 
            $extracted.add("RearMatterLang",$xml.Benchmark.'rear-matter'.lang) 
            $extracted.add("ReferenceHref",$xml.Benchmark.reference.href) 
            $extracted.add("ReferencePublisher",$xml.Benchmark.reference.publisher) 
            $extracted.add("ReferenceSource",$xml.Benchmark.reference.source)
            $extracted.add("Version",$xml.Benchmark.version) 
            
            foreach($ptItem in $xml.Benchmark.'plain-text'){
                $extracted.Add($ptItem.id,$ptItem.'#text')
            }
                $flatData = @()
            foreach($group in ($xml.Benchmark.group)){
                $flatData += [pscustomobject]@{
                    GroupID = $group.id
                    XmlVersion = $xml.xml
                    RuleID = $group.rule.id
                    Title = $group.title
                    Description = $group.description
                    Weight = $group.rule.weight
                    Severity =  $group.rule.severity
                    Version = $group.rule.version
                    RuleTitle = $group.rule.title
                    RuleDescription = $group.rule.description
                    ReferenceTitle = $group.rule.reference.title
                    ReferencePublisher = $group.rule.reference.publisher
                    ReferenceType = $group.rule.reference.type
                    ReferenceSubject = $group.rule.reference.subject
                    ReferenceIdentifier = $group.rule.reference.identifier
                    IdentSystem  = $group.rule.ident.system
                    IdentText = $group.rule.ident.'#text'
                    RuleFixRef = $group.rule.fixText.fixref
                    RuleFixText = $group.rule.fixText.'#text'
                    RuleFixID = $group.rule.fix.id
                    CheckSystem = $group.rule.check.system
                    CheckContent = $group.rule.check.'check-content'
                    CheckContentHref = $group.rule.check.'check-content-ref'.href
                    CheckContentName = $group.rule.check.'check-content-ref'.Name
                }
            }
            return @{
                metadata = $extracted
                STIGs = $flatData
            }
        }
    }
}
function CreateCheckList{
    param([hashtable]$fromSender)
    $ErrorActionPreference = "Stop"

    if($null -eq $fromSender){
        $fromSender = @{}
    }

    $globalManual = $fromSender
    $useGlobal = $false
    if($fromSender.ContainsKey("Manual")){
        $manualData = ExtractFromManual $globalManual
        $useGlobal = $true
    }
    
    $fromSender.CheckList | ForEach-Object {
        if(-not $useGlobal){
            if(($_.containskey("Manual"))){
                $manualData = ExtractFromManual ($_.Path)
            }else{
                return
            }
        }

        $rules = $_.Rules
        $export = $_.Export
        $name = ($_.Name).trim()
        $type = $_.type


        $content = switch($type){
            'cklb'{
                $uuid = (new-guid).guid
                $checklistHash = [ordered]@{
                title = ($name).trim()
                id = ((new-guid).guid).trim()
                    stigs = @(@{
                        stig_name = ($manualData.metadata.Title).trim()
                        display_name = ($manualData.STIGs[0].ReferenceSubject).trim()
                        stig_id = ($manualData.STIGs[0].CheckContentHref -replace (".xml","")).trim()
                        release_info = ($manualData.metadata."release-info").trim()
                        version = ($manualData.metadata.version).trim()
                        uuid = $uuid
                        reference_identifier = $manualData.stigs[0].ReferenceIdentifier
                        size =  $manualData.stigs.count
                        rules = @()
                    })
                    active = $true
                    mode = 2
                    hash_path = $false
                    target_data = @{
                        target_type = "Computing"
                        host_name = ""
                        ip_address = ""
                        mac_address = ""
                        fqdn = ""
                        comments = ""
                        role = "None"
                        is_web_database = $false
                        technology_area = ""
                        web_db_site = ""
                        web_db_instance = ""
                        classification = $null
                    }
                    cklb_version =  "1.0"
                }
                foreach($rule in $manualData.stigs){
                    $thisRule = @{
                        group_id_src = ($rule.GroupID).trim()
                        group_tree = @()
                        group_id = ($rule.GroupID).trim()
                    }
                    $thisRule.group_tree += @{
                        id = ($rule.GroupID).trim()
                        title = ($rule.title).trim()
                        description = ($rule.Description).trim()
                    }
                    $thisRule += @{
                        severity = ($rule.severity).trim()
                        group_title = ($rule.RuleTitle).trim()
                        rule_id_scr = ($rule.RuleID).trim()
                        rule_version = ($rule.version).trim()
                        rule_title = ($rule.RuleTitle).trim()
                        fix_text = ($rule.RuleFixText).trim()
                        weight = ($rule.weight).trim()
                        check_content = ($rule.CheckContent).trim()
                        check_content_ref = @{
                            href = $rule.Check
                            name = $rule.CheckContentName
                        }
                        classification = "Unclassified"
                        discussion = if($rule.RuleDescription -match '(?s)(<VulnDiscussion>)(.*)(</VulnDiscussion>)'){$matches[2]}else{""}
                        false_positives = if($rule.RuleDescription -match '(?s)(<FalsePositives>)(.*)(</FalsePositives>)'){$matches[2]}else{""}
                        false_negatives = if($rule.RuleDescription -match '(?s)(<FalseNegatives>)(.*)(</FalseNegatives>)'){$matches[2]}else{""}
                        documentable = if($rule.RuleDescription -match '(?s)(<Documentable>)(.*)(</Documentable>)'){$matches[2]}else{""}
                        security_override_guidance = if($rule.RuleDescription -match '(?s)(<SeverityOverrideGuidance>)(.*)(</SeverityOverrideGuidance>)'){$matches[2]}else{""}
                        potential_impacts = if($rule.RuleDescription -match '(?s)(<PotentialImpacts>)(.*)(</PotentialImpacts>)'){$matches[2]}else{""}
                        third_party_tools = if($rule.RuleDescription -match '(?s)(<ThirdPartyTools>)(.*)(</ThirdPartyTools>)'){$matches[2]}else{""}
                        ia_controls = if($rule.RuleDescription -match '(?s)(<IAControls>)(.*)(</IAControls>)'){$matches[2]}else{""}
                        responsibility = if($rule.RuleDescription -match '(?s)(<Responsibility>)(.*)(</Responsibility>)'){$matches[2]}else{""}
                        mitigations = if($rule.RuleDescription -match '(?s)(<Mitigations>)(.*)(</Mitigations>)'){$matches[2]}else{""}
                        mitigation_control = if($rule.RuleDescription -match '(?s)(<MitigationControl>)(.*)(</MitigationControl>)'){$matches[2]}else{""}
                        legacy_ids = @()
                    }
                    $thisRule.legacy_ids += ($rule.IdentText | where-object {$_ -notlike "CCI*"})
                    $thisRule += @{
                        ccis = @()
                    }
                    $thisRule.ccis += ($rule.IdentText | where-object {$_ -like "CCI*"})
                    $thisRule += @{
                        reference_identifier = "$(($rule.ReferenceIdentifier).trim())"
                        uuid = (new-guid).guid
                        stig_uuid = $uuid
                        status = "not_reviewed"
                        overrides = @{}
                        comments = ""
                        finding_details = ""
                    }
                    $checklistHash.stigs[0].rules += $thisRule
                }
                $checklistHash | convertto-json -depth 20
            }
            'ckl'{}
            default{
                -1
            }
        }

        if($content -ne -1){
        $checklistName = "{0}.{1}" -f $name, $type
        new-item -path (join-path $export.path $checklistName) -itemType 'File'  -value $content -force | out-null
        }else{
            return
        }
    }
}
function GetStig{
    param([hashtable]$fromSender)

    $checkLists = $fromSender.CheckList

    $checkLists | ForEach-Object {
        $path = $_.Path
        $item = get-item -path $path
        $type = $item.Extension

        switch($type){
            '.cklb'{
                $content = get-content -path $item.FullName
                $content | convertfrom-json
            }
            '.ckl'{}
            default{-1}
        }
    }
}
function UpdateCheckList{
    param([hashtable]$fromSender)

    $checkLists = $fromSender.CheckList
    $path = $fromSender.path
    $checkLists | ForEach-Object {

        $item = get-item -path $path
        $type = $item.Extension

        switch($type){
            '.cklb'{
                $content = get-content -path $item.FullName
                $checklistData = $content | convertfrom-json

                if($fromSender.CheckList.ContainsKey("title")){$checklistData.title = $fromSender.CheckList.title}
                if($fromSender.CheckList.ContainsKey("target_data")){
                    if($fromSender.CheckList.target_data.ContainsKey("technology_area")){ $checklistData.target_data.technology_area = $fromSender.checklist.technology_area }
                    if($fromSender.CheckList.target_data.ContainsKey("is_web_database")){ $checklistData.target_data.is_web_database = $fromSender.checklist.target_data.is_web_database }
                    if($fromSender.CheckList.target_data.ContainsKey("target_type")){ $checklistData.target_data.target_type = $fromSender.checklist.target_data.target_type }
                    if($fromSender.CheckList.target_data.ContainsKey("web_db_site")){ $checklistData.target_data.web_db_site = $fromSender.checklist.target_data.web_db_site }
                    if($fromSender.CheckList.target_data.ContainsKey("role")){ $checklistData.target_data.role = $fromSender.checklist.target_data.role }
                    if($fromSender.CheckList.target_data.ContainsKey("mac_address")){ $checklistData.target_data.role = $fromSender.checklist.target_data.mac_address }
                    if($fromSender.CheckList.target_data.ContainsKey("fqdn")){ $checklistData.target_data.role = $fromSender.checklist.target_data.fqdn }
                    if($fromSender.CheckList.target_data.ContainsKey("classification")){ $checklistData.target_data.classification = $fromSender.checklist.target_data.classification }
                    if($fromSender.CheckList.target_data.ContainsKey("comments")){ $checklistData.target_data.comments = $fromSender.checklist.target_data.comments }
                    if($fromSender.CheckList.target_data.ContainsKey("ip_address")){ $checklistData.target_data.ip_address = $fromSender.checklist.target_data.ip_address }
                    if($fromSender.CheckList.target_data.ContainsKey("host_name")){ $checklistData.target_data.host_name = $fromSender.checklist.target_data.host_name }
                    if($fromSender.CheckList.target_data.ContainsKey("web_db_instance")){ $checklistData.target_data.web_db_instance = $fromSender.checklist.target_data.web_db_instance }
                }
                if($fromSender.CheckList.ContainsKey("Stigs")){
                    $fromSender.CheckList.stigs | foreach-object {
  
                        if($_.containskey("rule_id")){$rule_id = $_.rule_id}else{$rule_id = $null}
                        if($_.containskey("status")){$status = $_.status}else{$status = $null}
                        if($_.containskey("comments")){$comments = $_.comments}else{$comments = $null}
                        if($_.containskey("finding_details")){$findingDetails = $_.finding_details}else{$findingDetails = $null}

                        if($null -ne $rule_id){
                            if($null -ne $status){($checklistData.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).status = $status}
                            if($null -ne $comments){($checklistData.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).comments = $comments}
                            if($null -ne $findingDetails){($checklistData.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).finding_details = $findingDetails}
                        }
                    }
                }

                $json = $checklistData | ConvertTo-Json -Depth 20
                Set-Content -Path $path -Value $json | Out-Null
            }
            '.ckl'{}
            default{-1}
        }
    }
}
function UpdateCheckListObjectVersion3{
    param([hashtable]$fromSender)

    $object = $fromSender.CheckListObject
    $path = $fromSender.path
    $object | ForEach-Object {

                if($fromSender.CheckList.ContainsKey("title")){$object.title = $fromSender.CheckList.title}
                if($fromSender.CheckList.ContainsKey("target_data")){
                    if($fromSender.CheckList.target_data.ContainsKey("technology_area")){ $object.target_data.technology_area = $fromSender.checklist.technology_area }
                    if($fromSender.CheckList.target_data.ContainsKey("is_web_database")){ $object.target_data.is_web_database = $fromSender.checklist.target_data.is_web_database }
                    if($fromSender.CheckList.target_data.ContainsKey("target_type")){ $object.target_data.target_type = $fromSender.checklist.target_data.target_type }
                    if($fromSender.CheckList.target_data.ContainsKey("web_db_site")){ $object.target_data.web_db_site = $fromSender.checklist.target_data.web_db_site }
                    if($fromSender.CheckList.target_data.ContainsKey("role")){ $object.target_data.role = $fromSender.checklist.target_data.role }
                    if($fromSender.CheckList.target_data.ContainsKey("mac_address")){ $object.target_data.role = $fromSender.checklist.target_data.mac_address }
                    if($fromSender.CheckList.target_data.ContainsKey("fqdn")){ $object.target_data.role = $fromSender.checklist.target_data.fqdn }
                    if($fromSender.CheckList.target_data.ContainsKey("classification")){ $object.target_data.classification = $fromSender.checklist.target_data.classification }
                    if($fromSender.CheckList.target_data.ContainsKey("comments")){ $object.target_data.comments = $fromSender.checklist.target_data.comments }
                    if($fromSender.CheckList.target_data.ContainsKey("ip_address")){ $object.target_data.ip_address = $fromSender.checklist.target_data.ip_address }
                    if($fromSender.CheckList.target_data.ContainsKey("host_name")){ $object.target_data.host_name = $fromSender.checklist.target_data.host_name }
                    if($fromSender.CheckList.target_data.ContainsKey("web_db_instance")){ $object.target_data.web_db_instance = $fromSender.checklist.target_data.web_db_instance }
                }
                if($fromSender.CheckList.ContainsKey("Stigs")){
                    $fromSender.CheckList.stigs | foreach-object {
  
                        if($_.containskey("rule_id")){$rule_id = $_.rule_id}else{$rule_id = $null}
                        if($_.containskey("status")){$status = $_.status}else{$status = $null}
                        if($_.containskey("comments")){$comments = $_.comments}else{$comments = $null}
                        if($_.containskey("finding_details")){$findingDetails = $_.finding_details}else{$findingDetails = $null}

                        if($null -ne $rule_id){
                            if($null -ne $status){($object.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).status = $status}
                            if($null -ne $comments){($object.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).comments = $comments}
                            if($null -ne $findingDetails){($object.stigs.rules | Where-Object {$_.group_id -eq $rule_id}).finding_details = $findingDetails}
                        }
                    }
                }
    }
                    $json = $object | ConvertTo-Json -Depth 20
                Set-Content -Path $path -Value $json | Out-Null
}
function CreateScriptRegistry{
    param([hashtable]$fromSender)

    $inputObject = $fromSender.InputObject
    

    $fileName = $fromSender.Name
    $path = $fromSender.Path

    $registryPath = join-path $path ("script-registry-{0}{1}" -f $fileName,'.csv')

    $entries = @()
    if(-not(test-path -path $registryPath)){
        foreach($rule in $inputObject.stigs){
            $entries += [pscustomobject]@{
                rule_id = $rule.GroupID
                rule_title = $rule.RuleTitle
                script_name = ""
                script_path = ""
                description = ""
            }
        }
        $csv = $entries | ConvertTo-Csv -NoTypeInformation
        new-item -path $registryPath -ItemType 'file' | out-null
        Set-Content -path $registryPath -Value $csv | Out-null
    }
}
function GetScriptRegistry{

    $name = $fromSender.Name
    $path = $fromSender.Path

    $registryPath = join-path $path ("{0}{1}"  -f $name,".csv")

    return Get-Content $registryPath | ConvertFrom-Csv 
}
