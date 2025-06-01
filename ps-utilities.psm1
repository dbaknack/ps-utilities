
# load private functions
$PRIVATE_PATH = Join-Path $PSScriptRoot "Private"
$private_files = Get-ChildItem -Path $PRIVATE_PATH -File -Filter "*.ps1" -Recurse
foreach($file in $private_files){
    . $file.FullName
}

# load public functions
$PUBLIC_PATH = Join-Path $PSScriptRoot "Public"
$public_files = Get-ChildItem -Path $PUBLIC_PATH -File -Filter "*.ps1" -Recurse
foreach($file in $public_files){
    . $file.FullName
}

# load on import
$RUN_PATH = Join-Path $PSScriptRoot "run"
$run_files = Get-ChildItem -Path $RUN_PATH -File -Filter "*.ps1" -Recurse
foreach($file in $run_files){
    . $file.FullName
}


