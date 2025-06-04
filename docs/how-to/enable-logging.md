# Enable message logging

Messages written via `Message2` can also be persisted to a log file. The location is controlled via the `Logging` section of the module configuration.

```powershell
# enable logging and set a custom path
(PSUtilConfig).Logging.Enabled = $true
(PSUtilConfig).Logging.Path = 'my-log.txt'
```

When enabled, each call to `Message2` will append the formatted log entry to the specified path.
