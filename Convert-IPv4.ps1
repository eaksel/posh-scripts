function Convert-IPv4 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$IPv4
    )
    
    begin {
    }
    
    process {
        foreach ($IPAddress in $IPv4) {
            $ValidIP = $IPAddress -match "^(\d{1,3}\.){3}\d{1,3}$"
            if ($ValidIP) {
                $OctetsBin = @()
                $OctetsHex = @()
                $Octets = $IPAddress -split "\."
                foreach ($Octet in $Octets) {
                    $OctetBin = [convert]::ToString($Octet, 2)
                    $OctetHex = [convert]::ToString($Octet, 16)
                    $OctetsBin += $OctetBin
                    $OctetsHex += $OctetHex
                }
                $IPProps = [ordered]@{
                    'IPAddress' = $IPAddress;
                    'Bin'       = $OctetsBin;
                    'Hex'       = $OctetsHex
                }
                $IPObj = New-Object -TypeName PSObject -Property $IPProps
                Write-Output $IPObj
            }
            else {
                Write-Warning "$IPAddress isn't matching the IPAddress regex."
            }
        }
    }
    
    end {
    }
}

If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Convert-IPv4
}