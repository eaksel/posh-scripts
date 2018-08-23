function Get-LocalAdminLPS {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName
    )
    
    begin {
        $so = New-PSSessionOption -SkipCACheck -SkipCNCheck
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            $AdminAccounts = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-LocalGroupMember -SID S-1-5-32-544 } -UseSSL -SessionOption $so
            foreach ($Account in $AdminAccounts) {
                $Account = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-LocalUser -SID $args[0].SID } -ArgumentList $Account -UseSSL -SessionOption $so
                $AccountProperties = [ordered]@{
                    'ComputerName'     = $Computer;
                    'UserName'         = $Account.Name;
                    'Enabled'          = $Account.Enabled;
                    'PasswordRequired' = $Account.PasswordRequired
                    'PasswordLastSet'  = $Account.PasswordLastSet;
                    'PasswordExpires'  = $Account.PasswordExpires;
                    'LastLogon'        = $Account.LastLogon
                }

                $AccountObject = New-Object -TypeName PSObject -Property $AccountProperties
                Write-Output $AccountObject
            }
        }
    }
    
    end {
    }
}

Get-LocalAdminLPS -ComputerName $env:COMPUTERNAME, localhost, $env:COMPUTERNAME | ft