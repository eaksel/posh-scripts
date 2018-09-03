$schema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetCurrentSchema()
$directoryentry = $schema.GetDirectoryEntry()

switch ($directoryentry.ObjectVersion) {
    13 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2000" }
    30 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2003" }
    31 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2003 R2" }
    44 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2008" }
    47 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2008 R2" }
    56 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2012" }
    69 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2012 R2" }
    87 { Write-Output "Schema Version $($directoryentry.ObjectVersion) = Windows 2016" }
    Default { Write-Output "Unkown Schema Version, $($directoryentry.ObjectVersion)" }
}

$forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

switch ($forest.ForestModeLevel) {
    0 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2000" }
    1 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2003 interim" }
    2 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2003" }
    3 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2008" }
    4 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2008 R2" }
    5 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2012" }
    6 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2012 R2" }
    7 { Write-Output "Forest Mode Level $($forest.ForestModeLevel) = Windows 2016" }
    Default { Write-Output "Unkown Forest Functional Level, $($directoryentry.ObjectVersion)" }
}

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

switch ($domain.DomainModeLevel) {
    0 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2000 Native" }
    1 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2003 Interim" }
    2 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2003" }
    3 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2008" }
    4 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2008 R2" }
    5 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2012" }
    6 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2012 R2" }
    7 { Write-Output "Domain Mode Level $($domain.DomainModeLevel) = Windows 2016" }
    Default { Write-Output "Unkown Domain Functional Level, $($directoryentry.ObjectVersion)" }
}