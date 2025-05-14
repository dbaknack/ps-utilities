import-module ./ps-utilities

# note:     any value in the json that is null will be converted to an empty string
$fromSender = @{
    Path = ".\tests\test.json"
}
ConvertfromJsonToHashtable $fromSender

# optional: remove the module when no longer needed
remove-module -name ps-utilities
