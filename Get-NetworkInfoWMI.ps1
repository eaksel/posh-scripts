function GenerateSearchBase {
    param (
        
    )
    $SearchBase = @()
    $DNSDomain = $env:USERDNSDOMAIN
    foreach ($element in $DNSDomain -split "\.") {
        $SearchBase += "DC=$element"
    }
    $SearchBase = $SearchBase -join ","
    Write-Output $SearchBase
}

function Get-NetworkInfoWMI {
    [CmdletBinding()]
    param (
        [string]$SearchBase,

        [switch]$LogErrors,

        [string]$ErrorLog = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "$(Get-Date -Format 'yyyy-MM-dd_HH-mm') - Error Log.log")
    )
    
    begin {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }

        Write-Verbose "The ErrorLog file will be saved as : $ErrorLog"

        $CheckFail = @()
        $InfoOK = @()
        $OffComputers = @()

        $WindowsComputers = (Get-ADComputer -SearchBase $SearchBase -Filter "OperatingSystem -Like 'Windows*'").Name | Sort-Object

        $ComputerCount = $WindowsComputers.count
        Write-Verbose "There are $ComputerCount computers to check :"

        $loop = 0
    }
    
    process {
        foreach ($Computer in $WindowsComputers) {
            $loop ++
            Write-Verbose "$loop of $ComputerCount `t$Computer"
            try {
                $null = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop
                try {
                    $NetInfo = Get-WMIObject -ComputerName $Computer -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" | Where-Object {$_.DefaultIPGateway}
                    $CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_ComputerSystem

                    $props = [Ordered]@{
                        'ComputerName' = $NetInfo.PSComputerName;
                        'IPAddress'    = $NetInfo.IPAddress -join ' & ';
                        'DNSServers'   = $NetInfo.DNSServerSearchOrder -join ' & ';
                        'MACAddress'   = $NetInfo.MACAddress;
                        'Model'        = $CompInfo.Model
                    }

                    $obj = New-Object -TypeName PSObject -Property $props
                    Write-Output $obj

                    $InfoOK += $Computer
                }
                catch {
                    $CheckFail += $Computer
                }
            }
            catch {
                $OffComputers += $Computer
            }
        }
    }
    
    end {
        if ($LogErrors) {
            "Summary for $($WindowsComputers.count) computers:" | Out-File -FilePath $ErrorLog -Append
            '' | Out-File -FilePath $ErrorLog -Append

            "Gathered WMI informations from $($InfoOK.count) computers:" | Out-File -FilePath $ErrorLog -Append
            $InfoOK -join (', ') |Out-File -FilePath $ErrorLog -Append
            '' | Out-File -FilePath $ErrorLog -Append

            "Couldn't gather WMI informations from $($CheckFail.count) computers:" | Out-File -FilePath $ErrorLog -Append
            $CheckFail -join (', ') | Out-File -FilePath $ErrorLog -Append
            '' |Out-File -FilePath $ErrorLog -Append

            "Unable to connect to $($OffComputers.count) computers:" | Out-File -FilePath $ErrorLog -Append
            $OffComputers -join (', ') | Out-File -FilePath $ErrorLog -Append
            '' | Out-File -FilePath $ErrorLog -Append
        }
    }
}

Get-NetworkInfoWMI -Verbose | Format-Table -AutoSize