import-module .\ps-utilities

# validate the commands available with this module
get-command -module ps-utilities

# optional: remove the module when no longer needed
remove-module -name ps-utilities