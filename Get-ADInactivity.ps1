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

function Get-ADComputerInactivity {
    param(
        [string]$SearchBase
    )
    BEGIN {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }
    }
    PROCESS {
        Get-ADComputer -SearchBase $SearchBase -Filter "Enabled -eq '$True'" -Properties LastLogonDate | Sort-Object LastLogonDate | Select-Object DNSHostName, LastLogonDate, @{N = "Inactivity (D)"; E = {((Get-date) - $_.LastLogonDate).days}}
    }
    END {
    }
}

function Get-ADUserInactivity {
    param(
        [string]$SearchBase
    )
    BEGIN {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }
    }
    PROCESS {
        Get-ADUser -SearchBase $SearchBase -Filter "Enabled -eq '$True'" -Properties LastLogonDate | Sort-Object LastLogonDate | Select-Object Name, LastLogonDate, @{N = "Inactivity (D)"; E = {((Get-date) - $_.LastLogonDate).days}}
    }
    END {
    }
}