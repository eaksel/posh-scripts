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
    BEGIN {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }
    }
    PROCESS {
        Get-ADUser -SearchBase $SearchBase -Filter "Enabled -eq '$True'" -Properties * | Select-Object CN, PasswordExpired, PasswordLastSet, LastLogonDate | Sort-Object CN
    }
    END {}
}