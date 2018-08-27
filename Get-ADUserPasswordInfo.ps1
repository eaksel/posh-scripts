function GenerateSearchBase {
    param ()
    $SearchBase = @()
    $DNSDomain = $env:USERDNSDOMAIN
    foreach ($element in $DNSDomain -split "\.") {
        $SearchBase += "DC=$element"
    }
    $SearchBase = $SearchBase -join ","
    Write-Output $SearchBase
}

function Get-ADUserPasswordInfo {
    param(
        [string]$SearchBase
    )
    begin {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }
    }
    process {
        Get-ADUser -SearchBase $SearchBase -Filter "Enabled -eq '$True'" -Properties * | Select-Object CN, PasswordExpired, PasswordLastSet, LastLogonDate, AccountExpirationDate, Enabled, LockedOut | Sort-Object CN
    }
    end {}
}