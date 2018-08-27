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

        [switch]$LogToFile,

        [string]$LogFile = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Get-NetworkInfoWMI - $(Get-Date -Format 'yyyy-MM-dd_HH-mm').log")
    )
    
    begin {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }

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
        if ($LogToFile) {
            Write-Verbose "The LogFile file will be saved as : $LogFile"
            
            "Summary for $($WindowsComputers.count) computers:" | Out-File -FilePath $LogFile -Append
            '' | Out-File -FilePath $LogFile -Append

            "Gathered WMI informations from $($InfoOK.count) computers:" | Out-File -FilePath $LogFile -Append
            $InfoOK -join (', ') |Out-File -FilePath $LogFile -Append
            '' | Out-File -FilePath $LogFile -Append

            "Couldn't gather WMI informations from $($CheckFail.count) computers:" | Out-File -FilePath $LogFile -Append
            $CheckFail -join (', ') | Out-File -FilePath $LogFile -Append
            '' |Out-File -FilePath $LogFile -Append

            "Unable to connect to $($OffComputers.count) computers:" | Out-File -FilePath $LogFile -Append
            $OffComputers -join (', ') | Out-File -FilePath $LogFile -Append
            '' | Out-File -FilePath $LogFile -Append
        }
    }
}

If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Get-NetworkInfoWMI
}