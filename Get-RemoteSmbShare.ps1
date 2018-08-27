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
        
        [string]$LogFile = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Get-RemoteSmbShare - $(Get-Date -Format 'yyyy-MM-dd_HH-mm').log")
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
                $Computer | Out-File $LogFile -Append
            }
            if ($ComputerOK) {
                foreach ($smbshare in $smbshares) {
                    
                    $SMBprops = [Ordered]@{
                        'ComputerName' = $Computer;
                        'SmbShare'    = $smbshare.Name;
                        'Path'        = $smbshare.Path;
                        'Description'  = $smbshare.Description
                    }
                    $SMBobj = New-Object -TypeName PSObject -Property $SMBprops
                    Write-Output $SMBobj
                }
            }
        }
    }
    
    end {
    }
}

If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Get-RemoteSmbShare
}