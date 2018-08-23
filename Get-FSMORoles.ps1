Function Get-FSMORoles {
    [CmdletBinding()]
    param(
        [string]$DomainName = $env:USERDNSDOMAIN
    )
    try {
        $DomainObj = Get-ADDomain -Server $DomainName -ErrorAction Stop
        $ForestObj = Get-ADForest -Server $DomainName -ErrorAction Stop
        $FSMOProps = @{
            'PDCEmulator'          = $DomainObj.PDCEmulator;
            'RIDMaster'            = $DomainObj.RIDMaster;
            'InfrastructureMaster' = $DomainObj.InfrastructureMaster;
            'SchemaMaster'         = $ForestObj.SchemaMaster;
            'DomainNamingMaster'   = $ForestObj.DomainNamingMaster
        }
        $FSMOObj = New-Object -TypeName PSObject -Property $FSMOProps
        Write-Output $FSMOObj
    }
    catch {
        Write-Warning "Failed to query the domain '$DomainName'. Verify that the domain name is valid."
    }
}