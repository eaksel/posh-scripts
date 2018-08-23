function Get-EmptyGPO {
<#
.SYNOPSIS
Retrieves a list of GPOs. Can tell if a GPO was created and never configured.
.DESCRIPTION
See the sysnopsis.
.PARAMETER EmptyOnly
Switch parameter, when used lists only GPOs that were created and never configured.
Get-EmptyGPO -EmptyOnly
.EXAMPLE
 Get-EmptyGPO
 This example retrieves all the GPOs and output the following info: 'Name', 'Empty', 'Owner', 'CreationTime', 'ModificationTime', 'ID'.
.EXAMPLE
 Get-EmptyGPO -EmptyOnly
 This example retrieves only GPOs that were created and never configured and output the following info: 'Name', 'Empty', 'Owner', 'CreationTime', 'ModificationTime', 'ID'.
#>
    [CmdletBinding()]
    param (
        [switch]$EmptyOnly
    )
    
    begin {
        try {
            Import-Module GroupPolicy -ErrorAction Stop
        }
        catch {
            Write-Output "Can't import the module 'GroupPolicy'. Exiting."
            exit 1
        }
    }
    
    process {
        $GPOs = Get-Gpo -All
        if ($GPOs) {
            foreach ($GPO in $GPOs) {
                if ($GPO.Computer.DSVersion -eq 0 -and $GPO.User.DSVersion -eq 0) {
                    $GPOProps = [Ordered]@{
                        'Name'             = $GPO.Displayname;
                        'Empty'            = $True;
                        'Owner'            = $GPO.Owner;
                        'CreationTime'     = $GPO.CreationTime;
                        'ModificationTime' = $GPO.ModificationTime;
                        'ID'               = $GPO.Id
                    }
                    $GPOObject = New-Object -TypeName PSObject -Property $GPOProps
                    Write-Output $GPOObject
                }
                else {
                    $GPOProps = [Ordered]@{
                        'Name'             = $GPO.Displayname;
                        'Empty'            = $False;
                        'Owner'            = $GPO.Owner;
                        'CreationTime'     = $GPO.CreationTime;
                        'ModificationTime' = $GPO.ModificationTime;
                        'ID'               = $GPO.Id
                    }
                    $GPOObject = New-Object -TypeName PSObject -Property $GPOProps
                    if (! $EmptyOnly) {
                        Write-Output $GPOObject
                    }
                }
            }
        }
        else {
            Write-Output "Couldn't find any GPO."
        }
    }
    
    end {
    }
}