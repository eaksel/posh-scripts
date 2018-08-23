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

function Get-ADComputerSystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = "Enter a SearchBase without quotes ex: OU=Domain Controllers,DC=ad,DC=example,DC=com")]
        [string]$SearchBase,

        [switch]$LogToFile,

        [string]$LogFile = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Get-ADComputerSystemInfo - $(Get-Date -Format 'yyyy-MM-dd').csv")
    )
    
    BEGIN {
        if (! $SearchBase) {
            $SearchBase = GenerateSearchBase
        }

        $Successful = @()
        $CimError = @()

        if ($LogToFile) {
            if (Test-Path $LogFile) {
                Remove-Item -Path $LogFile
            }
        }

        try {
            $WindowsComputers = (Get-ADComputer -SearchBase "$SearchBase" -Filter "OperatingSystem -Like 'Windows*'").Name | Sort-Object
        }
        catch {
            Write-Output "Couldn't connect to the specified SearchBase ($SearchBase)"
            Write-Warning $error[0]
            Exit
        }

        Write-Verbose "There are $($WindowsComputers.count) computers to check :"
        $counter = 0
    }

    PROCESS {
        foreach ($Computer in $WindowsComputers) {
            $counter += 1

            Write-Verbose "$counter of $($WindowsComputers.count) : `t$Computer"

            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
                if ($os) {
                    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computer
                    $bios = Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computer
                    $net = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $Computer  -Filter "ipenabled = 'true'" | Where-Object {$_.DNSServerSearchOrder -ne $null}
                    $proc = Get-CimInstance -ClassName Win32_Processor -ComputerName $Computer | Select-Object -First 1
                    $route = Get-CimInstance -ClassName Win32_IP4RouteTable -ComputerName $Computer -Filter "Type = '4'"
                    $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType=3"

                    $DiskCollection = @()
                    foreach ($Disk in $Disks) {
                        $diskprops = [ordered]@{
                            'DriveLetter'    = $disk.deviceid;
                            'DriveType'      = $disk.drivetype;
                            'Size(GB)'       = "{0:N2}" -f ($disk.Size / 1GB);
                            'FreeSpace(GB)'  = "{0:N2}" -f ($disk.FreeSpace / 1GB);
                            'FreePercent(%)' = "{0:N2}" -f ($disk.FreeSpace / $disk.Size * 100)
                        }
                        $DiskObject = New-Object -TypeName PSObject -Property $diskprops
                        $DiskCollection += $DiskObject
                    }

                    $properties = [ordered]@{
                        'ComputerName' = $cs.Name;
                        'FQDN'         = $net.DNSHostName;
                        'OSVersion'    = $os.Version;
                        'SPVersion'    = $os.ServicePackMajorVersion;
                        'Architecture' = $os.OSArchitecture;
                        'Manufacturer' = $cs.Manufacturer;
                        'Model'        = $cs.Model;
                        'RAM(GB)'      = "{0:N2}" -f ($cs.TotalPhysicalMemory / 1GB);
                        'BIOSSerial'   = $bios.SerialNumber;
                        'Processor'    = $proc.Name;
                        'IPAddress'    = $net.IPAddress -join ' / ';
                        'DNSServers'   = $net.DNSServerSearchOrder -join ' / ';
                        'MACAddress'   = $net.MACAddress -join ' / ';
                        'Gateway'      = $route.NextHop;
                        'Disks'        = $DiskCollection
                    }

                    $obj = New-Object -TypeName psobject -Property $properties
                    Write-Output $obj

                    if ($LogToFile) {
                        $obj | Export-Csv -Path $LogFile -Append -NoTypeInformation
                    }

                    $Successful += $Computer
                }
            }
            catch {
                $CimError += $Computer
                Write-Warning "Unable to gather informations via CimInstance for `t$Computer"
            }
        }
    }
    END {
        Write-Verbose "$($Successful.count) hosts were tested successfully."
        Write-Verbose ("-" * 60)
        Write-Verbose "$($CimError.count) hosts wouldn't accept Cim requests or were offline."
        Write-Verbose ("-" * 60)
        Write-Verbose "The CSV File with the gathered informations is located at:"
        Write-Verbose $LogFile
    }
}

Get-ADComputerSystemInfo