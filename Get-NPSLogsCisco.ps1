<#
.SYNOPSIS
    Parse NPS DTS compliant log files.
.DESCRIPTION
    Parse NPS DTS Compliant log files.
.EXAMPLE
    PS C:\> Get-NPSLogsCisco -LogFile "C:\Windows\System32\LogFiles\IN1910.log"
    Parse a log file.
.EXAMPLE
    PS C:\> Get-NPSLogsCisco -LogFile "C:\Windows\System32\LogFiles\IN1910.log" | Format-Table Computer-Name, Event-Source, User-Name, Called-Station-Id, Calling-Station-Id, NAS-IP-Address, NAS-Port-Id, Proxy-Policy-Name, NP-Policy-Name
    Parse logs, format as a table with specific properties.
.EXAMPLE
    PS C:\> Get-NPSLogsCisco -LogFile "C:\Windows\System32\LogFiles\IN1910.log" | Where-Object { $_."Packet-Type-Name" -eq "Access-Accept" } | Format-Table Timestamp, Computer-Name, Event-Source, Proxy-Policy-Name, NP-Policy-Name, Client-IP-Address, SAM-Account-Name
    Parse logs, select lines where "Packet-Type-Name" -eq "Access-Accept", format as a table with specific properties.
#>


function Get-NPSLogsCisco {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$LogFile
    )

    # Meaning of RADIUS values
    $PACKET_TYPES = @{
        1  = "Access-Request"
        2  = "Access-Accept"
        3  = "Access-Reject"
        4  = "Accounting-Request"
        5  = "Accounting-Response"
        6  = "Accounting-Status"
        7  = "Password-Request"
        8  = "Password-Ack"
        9  = "Password-Reject"
        10 = "Accounting-Message"
        11 = "Access-Challenge"
        21 = "Resource-Free-Request"
        22 = "Resource-Free-Response"
        23 = "Resource-Query-Request"
        24 = "Resource-Query-Response"
        25 = "Alternate-Resource-Reclaim-Request"
        26 = "NAS-Reboot-Request"
        27 = "NAS-Reboot-Response"
        29 = "Next-Passcode"
        30 = "New-Pin"
        31 = "Terminate-Session"
        32 = "Password-Expired"
        33 = "Event-Request"
        34 = "Event-Response"
        40 = "Disconnect-Request"
        41 = "Disconnect-ACK"
        42 = "Disconnect-NAK"
        43 = "CoA-Request"
        44 = "CoA-ACK"
        45 = "CoA-NAK"
        50 = "IP-Address-Allocate"
        51 = "IP-Address-Release"
    }

    $AUTHENTICATION_TYPES = @{ 
        1  = "PAP"
        2  = "CHAP"
        3  = "MS-CHAP"
        4  = "MS-CHAP v2"
        5  = "EAP"
        7  = "None"
        8  = "Custom"
        11 = "PEAP"
    }

    $REASON_CODES = @{
        0  = "IAS_SUCCESS"
        1  = "IAS_INTERNAL_ERROR"
        2  = "IAS_ACCESS_DENIED"
        3  = "IAS_MALFORMED_REQUEST"
        4  = "IAS_GLOBAL_CATALOG_UNAVAILABLE"
        5  = "IAS_DOMAIN_UNAVAILABLE"
        6  = "IAS_SERVER_UNAVAILABLE"
        7  = "IAS_NO_SUCH_DOMAIN"
        8  = "IAS_NO_SUCH_USER"
        16 = "IAS_AUTH_FAILURE"
        17 = "IAS_CHANGE_PASSWORD_FAILURE"
        18 = "IAS_UNSUPPORTED_AUTH_TYPE"
        32 = "IAS_LOCAL_USERS_ONLY"
        33 = "IAS_PASSWORD_MUST_CHANGE"
        34 = "IAS_ACCOUNT_DISABLED"
        35 = "IAS_ACCOUNT_EXPIRED"
        36 = "IAS_ACCOUNT_LOCKED_OUT"
        37 = "IAS_INVALID_LOGON_HOURS"
        38 = "IAS_ACCOUNT_RESTRICTION"
        48 = "IAS_NO_POLICY_MATCH"
        64 = "IAS_DIALIN_LOCKED_OUT"
        65 = "IAS_DIALIN_DISABLED"
        66 = "IAS_INVALID_AUTH_TYPE"
        67 = "IAS_INVALID_CALLING_STATION"
        68 = "IAS_INVALID_DIALIN_HOURS"
        69 = "IAS_INVALID_CALLED_STATION"
        70 = "IAS_INVALID_PORT_TYPE"
        71 = "IAS_INVALID_RESTRICTION"
        80 = "IAS_NO_RECORD"
        96 = "IAS_SESSION_TIMEOUT"
        97 = "IAS_UNEXPECTED_REQUEST"
    }

    $ACCT_STATUS_TYPES = @{
        1  = "Start"
        2  = "Stop"
        3  = "Interim-Update"
        7  = "Accounting-On"
        8  = "Accounting-Off"
        9  = "Tunnel-Start"
        10 = "Tunnel-Stop"
        11 = "Tunnel-Reject"
        12 = "Tunnel-Link-Start"
        13 = "Tunnel-Link-Stop"
        14 = "Tunnel-Link-Reject"
        15 = "Failed"
    }

    $NAS_PORT_TYPES = @{
        0  = "Async"
        1  = "Sync"
        2  = "ISDN Sync"
        3  = "ISDN Async V.120"
        4  = "ISDN Async V.110"
        5  = "Virtual"
        6  = "PIAFS"
        7  = "HDLC Clear Channel"
        8  = "X.25"
        9  = "X.75"
        10 = "G.3 Fax"
        11 = "SDSL - Symmetric DSL"
        12 = "ADSL-CAP - Asymmetric DSL, Carrierless Amplitude Phase Modulation"
        13 = "ADSL-DMT - Asymmetric DSL, Discrete Multi-Tone"
        14 = "IDSL - ISDN Digital Subscriber Line"
        15 = "Ethernet"
        16 = "xDSL - Digital Subscriber Line of unknown type"
        17 = "Cable"
        18 = "Wireless - Other"
        19 = "Wireless - IEEE 802.11"
    }

    $PROVIDER_TYPES = @{
        0 = "None"
        1 = "Windows"
        2 = "RADIUS Proxy"
    }

    # Begining of the script

    $LogContent = Get-Content $LogFile

    $AllLogObjects = @()

    foreach ($LogEntry in $LogContent) {
        $LogEntry = [xml]$LogEntry
        $LogEntry = $LogEntry.Event

        $LogProperties = [ordered]@{
            "Timestamp"                = $LogEntry."Timestamp"."#text"
            "Computer-Name"            = $LogEntry."Computer-Name"."#text"
            "Event-Source"             = $LogEntry."Event-Source"."#text"
            "User-Name"                = $LogEntry."User-Name"."#text"
            "Called-Station-Id"        = $LogEntry."Called-Station-Id"."#text"
            "Calling-Station-Id"       = $LogEntry."Calling-Station-Id"."#text"
            "NAS-Port"                 = $LogEntry."NAS-Port"."#text"
            "NAS-IP-Address"           = $LogEntry."NAS-IP-Address"."#text"
            "NAS-Port-Id"              = $LogEntry."NAS-Port-Id"."#text"
            "NAS-Port-Type"            = $LogEntry."NAS-Port-Type"."#text"
            "NAS-Port-Type-Name"       = $NAS_PORT_TYPES[[int]$LogEntry."NAS-Port-Type"."#text"]
            "Acct-Session-Id"          = $LogEntry."Acct-Session-Id"."#text"
            "Framed-IP-Address"        = $LogEntry."Framed-IP-Address"."#text"
            "Class"                    = $LogEntry."Class"."#text"
            "Acct-Status-Type"         = $LogEntry."Acct-Status-Type"."#text"
            "Acct-Status-Type-Name"    = $ACCT_STATUS_TYPES[[int]$LogEntry."Acct-Status-Type"."#text"]
            "Event-Timestamp"          = $LogEntry."Event-Timestamp"."#text"
            "Acct-Input-Octets"        = $LogEntry."Acct-Input-Octets"."#text"
            "Acct-Output-Octets"       = $LogEntry."Acct-Output-Octets"."#text"
            "Acct-Input-Packets"       = $LogEntry."Acct-Input-Packets"."#text"
            "Acct-Output-Packets"      = $LogEntry."Acct-Output-Packets"."#text"
            "Acct-Delay-Time"          = $LogEntry."Acct-Delay-Time"."#text"
            "Client-IP-Address"        = $LogEntry."Client-IP-Address"."#text"
            "Client-Vendor"            = $LogEntry."Client-Vendor"."#text"
            "Client-Friendly-Name"     = $LogEntry."Client-Friendly-Name"."#text"
            "Cisco-AV-Pair"            = $LogEntry."Cisco-AV-Pair"."#text"
            "Proxy-Policy-Name"        = $LogEntry."Proxy-Policy-Name"."#text"
            "NP-Policy-Name"           = $LogEntry."NP-Policy-Name"."#text"
            "Tunnel-Type"              = $LogEntry."Tunnel-Type"."#text"
            "Tunnel-Pvt-Group-ID"      = $LogEntry."Tunnel-Pvt-Group-ID"."#text"
            "Tunnel-Medium-Type"       = $LogEntry."Tunnel-Medium-Type"."#text"
            "Provider-Type"            = $LogEntry."Provider-Type"."#text"
            "Provider-Type-Name"       = $PROVIDER_TYPES[[int]$LogEntry."Provider-Type"."#text"]
            "SAM-Account-Name"         = $LogEntry."SAM-Account-Name"."#text"
            "Fully-Qualifed-User-Name" = $LogEntry."Fully-Qualifed-User-Name"."#text"
            "Authentication-Type"      = $LogEntry."Authentication-Type"."#text"
            "Authentication-Type-Name" = $AUTHENTICATION_TYPES[[int]$LogEntry."Authentication-Type"."#text"]
            "Packet-Type"              = $LogEntry."Packet-Type"."#text"
            "Packet-Type-Name"         = $PACKET_TYPES[[int]$LogEntry."Packet-Type"."#text"]
            "Reason-Code"              = $LogEntry."Reason-Code"."#text"
            "Reason-Code-Name"         = $REASON_CODES[[int]$LogEntry."Reason-Code"."#text"]
        }
        $LogObject = New-Object -TypeName PSObject -Property $LogProperties
        $AllLogObjects += $LogObject
    }
    Write-Output $AllLogObjects
}

Get-NPSLogsCisco