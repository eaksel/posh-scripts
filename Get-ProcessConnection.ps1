function Get-ProcessConnection {
<#
.SYNOPSIS
    Retreive a list of running processes that have an active network connection and display them.
.EXAMPLE
    PS C:\> Get-ProcessConnection | Sort-Object ProcessID, RemotePTR | Format-Table
    Get process connection information, sort by process id and remote address, format as a table.
#>
    [CmdletBinding()]
    param (
        [string[]]$ProcessName = "*",
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $results = @()
    }

    process {
        foreach ($Computer in $ComputerName) {
            $session = New-PSSession -ComputerName $Computer
            $processes = Invoke-Command -Session $session -ScriptBlock { Get-Process -IncludeUserName -Name $using:ProcessName }
            $connections = Invoke-Command -Session $session -ScriptBlock {
                Get-NetTCPConnection -State Established -OwningProcess $using:processes.id |
                Where-Object { $_.RemoteAddress -ne "127.0.0.1" -and $_.RemoteAddress -ne "::1" }
            }
            Remove-PSSession $session

            foreach ($conn in $connections) {
                # Get the PTR of the remote IP
                try {
                    $ptr = (Resolve-DnsName -Name $conn.RemoteAddress -DnsOnly -ErrorAction Stop).NameHost
                }
                catch {
                    $ptr = "N/A"
                }
                $props = [Ordered]@{
                    ProcessName   = $processes | Where-Object { $_.Id -eq $conn.OwningProcess } | Select-Object -ExpandProperty ProcessName
                    ProcessID     = $conn.OwningProcess
                    RemoteAddress = $conn.RemoteAddress
                    RemotePort    = $conn.RemotePort
                    RemotePTR     = $ptr
                    UserName      = $processes | Where-Object { $_.Id -eq $conn.OwningProcess } | Select-Object -ExpandProperty UserName
                    ComputerName  = $Computer
                }
                $obj = New-Object -TypeName psobject -Property $props
                $results += $obj
            }
        }
    }

    end {
        Write-Output $results
    }
}

Get-ProcessConnection | Sort-Object ProcessID, RemotePTR | Format-Table