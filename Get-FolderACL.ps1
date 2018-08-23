function Get-FolderACL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage="Enter a path (Ex: D:\Share)")]
        [string]$ParentFolder,
        
        [switch]$LogErrors,

        [string]$ErrorLog = (Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Get-FolderACL - $(Get-Date -Format 'yyyy-MM-dd_HH-mm').log")
    )
    
    begin {
        Write-Verbose "The ErrorLog file will be saved as : $ErrorLog"

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
        if ($LogErrors) {
            "Summary for $($FolderCount) folders:" | Out-File -FilePath $ErrorLog -Append
            '' | Out-File -FilePath $ErrorLog -Append
            "Gathered folder ACLs from $($InfoOK.count) folders:" | Out-File -FilePath $ErrorLog -Append
            $InfoOK -join (', ') | Out-File -FilePath $ErrorLog -Append
            '' | Out-File -FilePath $ErrorLog -Append
            "Couldn't gather folder ACLs from $($CheckFail.count) folders:" | Out-File -FilePath $ErrorLog -Append
            $CheckFail -join (', ') | Out-File -FilePath $ErrorLog -Append
            '' |Out-File -FilePath $ErrorLog -Append
        }
    }
}

Get-FolderACL -ParentFolder C:\ -Verbose | Select-Object -ExpandProperty ACLs | ConvertTo-Csv