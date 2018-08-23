function Get-SystemInfo {
    <#
.SYNOPSIS
    Retrieves key system version and model information from one to ten computers.
.DESCRIPTION
    Get-SystemInfo uses Windows Management Instrumentation (WMI) to retrieve information from one or more computers. Specify computers by name or by IP address.
.PARAMETER ComputerName
    One or more computer names or IP addresses, up to a maximum of 10.
.PARAMETER LogErrors
    Specify this switch to create a text log file of computers that could not be queried.
.PARAMETER ErrorLog
    When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to C:\Retry.txt.
.EXAMPLE
    Get-Content names.txt | Get-SystemInfo
.EXAMPLE
    Get-SystemInfo -ComputerName SERVER1,SERVER2
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            HelpMessage = "Computer name or IP address")]
        [ValidateCount(1, 10)]
        [Alias('HostName')]
        [string[]]$ComputerName,

        [string]$ErrorLog = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Retry.log"),
        
        [switch]$LogErrors
    )
    
    begin {
        Write-Verbose "Log name is $ErrorLog"
        if (Test-Path -Path $ErrorLog) {
            Remove-Item -Path $ErrorLog
            Write-Warning "Old $ErrorLog file was deleted"
        }
    }
    
    process {
        Write-Verbose "Beginning PROCESS block"
        foreach ($computer in $ComputerName) {
            Write-Verbose "Querying $computer"
            try {
                $everything_ok = $true
                $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
            }
            catch {
                $everything_ok = $false
                Write-Warning "$computer failed"
                Write-Warning "$computer : $_.Exception.Message"
                if ($LogErrors) {
                    $computer | Out-File $ErrorLog -Append
                    Write-Warning "Logged to $ErrorLog"
                }
            }
            if ($everything_ok) {
                $comp = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer
                $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $computer

                $props = @{'ComputerName' = $computer;
                    'OSVersion' = $os.version;
                    'SPVersion' = $os.servicepackmajorversion;
                    'BIOSSerial' = $bios.serialnumber;
                    'Manufacturer' = $comp.manufacturer;
                    'Model' = $comp.model;
                    'LastBootUpTime' = $os.ConvertToDateTime($os.LastBootUpTime)
                }
            
                Write-Verbose "WMI queries complete"
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
    
    end {
    }
}

Get-SystemInfo -ComputerName noton, localhost -LogErrors