function Get-RemoteSmbShare {
    <#
.SYNOPSIS
    Get-RemoteSmbShare
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-RemoteSmbShare -ComputerName $env:COMPUTERNAME, localhost
    Retrieves SMB shares on the specified computers.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Alias("HostName")]
        [ValidateCount(1, 5)]
        [string[]]$ComputerName,
        
        [string]$ErrorFile = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "$(Get-Date -Format 'yyyy-MM-dd_HH-mm') - Error Log.log")
    )
    
    begin {
        $so = New-PSSessionOption -SkipCACheck -SkipCNCheck
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            try {
                $ComputerOK = $True
                $smbshares = Invoke-Command -ComputerName $Computer -UseSSL -SessionOption $so -ScriptBlock {Get-SmbShare} -ErrorAction Stop
            }
            catch {
                $ComputerOK = $False
                Write-Warning "$Computer : Error while getting info."
                Write-Warning "$Computer : $_.Exception.Message"
                $Computer | Out-File $ErrorFile -Append
            }
            if ($ComputerOK) {
                $props = [Ordered]@{'ComputerName' = $Computer;
                    'SmbShares'           = $smbshares.Name;
                    'Paths'               = $smbshares.Path;
                    'Description'         = $smbshares.Description
                }
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
    
    end {
    }
}

Get-RemoteSmbShare -computer $env:COMPUTERNAME, localhost