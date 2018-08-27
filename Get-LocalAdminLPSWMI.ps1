function Get-LocalAdminLPSWMI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$ComputerName
    )
    
    begin {
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            $AdminGroup = Get-WmiObject -Class Win32_Group -Filter "SID='S-1-5-32-544'"
            $AdminAccounts = $AdminGroup.GetRelated("Win32_Account", "Win32_GroupUser", "", "", "PartComponent", "GroupComponent", $FALSE, $NULL)
            foreach ($Account in $AdminAccounts) {
                $AccountProperties = [ordered]@{
                    'ComputerName'     = $Computer;
                    'UserName'         = $Account.Name;
                    'Domain'           = $Account.Domain;
                    'Disabled'         = $Account.Disabled;
                    'PasswordRequired' = $Account.PasswordRequired;
                    'PasswordExpires'  = $Account.PasswordExpires;
                    'Description'      = $Account.Description
                }
                
                $AccountObject = New-Object -TypeName PSObject -Property $AccountProperties
                Write-Output $AccountObject
            }
        }
    }
    
    end {
    }
}

If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Get-LocalAdminLPSWMI
}