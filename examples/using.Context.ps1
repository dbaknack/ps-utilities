import-module ./ps-utilities

# ----------------------------------------------------------------------------------
# ex.   defining your parameters first #
# note: useful when passing into a function
$fromSender = @{
    NonDefaultParam1 = "NonDefaultParam1"
    NonDefaultParam2 = "NonDefaultParam2"
    NonDefaultParam3 = 1234
}

# merge it with the defaults
Context $fromSender

$fromSender = Context $fromSender

# updating the defaults
$fromSender.Preferences.Messages.Enabled = $false
$fromSender.Preferences.Messages.Enabled
# ----------------------------------------------------------------------------------
# ex.   working with context only
# note: useful when controlling context initally

$context = Context
$context.Preferences.Messages.Enabled = $false
$context.Preferences.Messages.Enabled
# ----------------------------------------------------------------------------------


# optional: remove the module when no longer needed
remove-module -name ps-utilities

Message

(Context).Stores