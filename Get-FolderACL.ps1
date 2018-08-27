function Get-FolderACL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage="Enter a path (Ex: D:\Share)")]
        [string]$ParentFolder,
        
        [switch]$LogToFile,

        [string]$LogFile = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Get-FolderACL - $(Get-Date -Format 'yyyy-MM-dd_HH-mm').log")
    )
    
    begin {
        $CheckFail = @()
        $InfoOK = @()

        $Folders = (Get-ChildItem -Path $ParentFolder).FullName

        $FolderCount = $Folders.count

        Write-Verbose "There are $FolderCount folders to check :"

        $loop = 0
    }
    
    process {
        foreach ($Folder in $Folders) {
            $loop ++
            Write-Verbose "$loop of $FolderCount `t$Folder"
            try {
                $ACLs = (Get-Acl -Path $Folder).Access
                $ACLsObj = @()
                foreach ($ACL in $ACLs) {
                    $ACLprops = [ordered]@{
                        'FolderName'        = $Folder;
                        'AccessControlType' = $ACL.AccessControlType;
                        'NTFS Rights'       = $ACL.FileSystemRights;
                        'IdentityReference' = $ACL.IdentityReference
                    }
                    $ACLObj = New-Object -Type PSObject -Property $ACLprops
                    $ACLsObj += $ACLObj
                }
                $MainProps = @{
                    'Folder' = $Folder;
                    'ACLs'   = $ACLsObj
                }
                $MainObj = New-Object -TypeName PSObject -Property $MainProps
                Write-Output $MainObj

                $InfoOK += $Folder
            }
            catch {
                $CheckFail += $Folder
            }
        }
    }
    
    end {
        if ($LogToFile) {
            Write-Verbose "The LogFile will be saved as : $LogFile"

            "Summary for $($FolderCount) folders:" | Out-File -FilePath $LogFile -Append
            '' | Out-File -FilePath $LogFile -Append

            "Gathered folder ACLs from $($InfoOK.count) folders:" | Out-File -FilePath $LogFile -Append
            $InfoOK -join (', ') | Out-File -FilePath $LogFile -Append
            '' | Out-File -FilePath $LogFile -Append
            
            "Couldn't gather folder ACLs from $($CheckFail.count) folders:" | Out-File -FilePath $LogFile -Append
            $CheckFail -join (', ') | Out-File -FilePath $LogFile -Append
            '' |Out-File -FilePath $LogFile -Append
        }
    }
}

If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Get-FolderACL
}