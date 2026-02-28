<#
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//SOURCE-INFORMATION//
NAME: peer-2-peer-tcp-chat
VERSION: 20260228.0.0 aka v0
DIRECTION: Greg Focaccio
CODE: OpenAI GPT-5 Codex
TESTING: not yet executed in this environment
...............................................................................................
//FEATURES//
1. A and Z side peer to peer TCP chat with user specified IP addresses and ports
2. Implemented in PowerShell with separate A side and Z side executables
3. 2 unidirectional TCP channels (1. A > Z; 2. Z > A) for full duplex messaging
4. A and Z both transmit message probes every 10 seconds with receive reporting
...............................................................................................
//SYSTEM-REQUIRMENTS//
1. Operating System:
Microsoft Windows 10/11 (64-bit) or
Windows Server 2019/2022 with Desktop Experience.
2. PowerShell:
Windows PowerShell 5.1 (recommended)
or PowerShell 7.x on
Windows with
System.Windows.Forms
System.Drawing
...............................................................................................
//OPERATION//
1. Run a-side-tcp-chat-v0.ps1 on A side then enter A, Z IP addresses and ports then Apply
2. Run z-side-tcp-chat-v0.ps1 on Z side then enter A, Z IP addresses and ports then Apply
...............................................................................................
//CHANGE-LOG//
20260228.0.0 refactored transport from UDP to TCP
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#>

param(
    [string]$SideAIP = '127.0.0.1',
    [string]$SideZIP = '0.0.0.0',

    [int]$SideAToSideZSourcePort = 7000,
    [int]$SideAToSideZDestPort = 7000,
    [int]$SideZToSideASourcePort = 7001,
    [int]$SideZToSideADestPort = 7001,

    [string]$DisplayName = 'Side Z'
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$maxInputLines = 3
$probePayloadText = 'ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ'
$remoteProbePayloadText = 'AAAAA-AAAAA-AAAAA-AAAAA-AAAAA'
$probePayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($probePayloadText)
$connectRetryIntervalMs = 3000
$connectTimeoutMs = 5000

$fontMain = New-Object System.Drawing.Font('Segoe UI', 12)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 10)
$fontTitle = New-Object System.Drawing.Font('Segoe UI Semibold', 13)

$form = New-Object System.Windows.Forms.Form
$form.Text = "TCP P2P Chat - $DisplayName"
$form.Size = New-Object System.Drawing.Size(1080, 780)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(920, 640)
$form.KeyPreview = $true
$form.AutoScaleMode = 'Dpi'

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(14, 12)
$lblTitle.Size = New-Object System.Drawing.Size(1020, 28)
$lblTitle.Font = $fontTitle
$lblTitle.Text = "Peer-to-Peer TCP Chat ($DisplayName)"
$form.Controls.Add($lblTitle)

$lblSideAIP = New-Object System.Windows.Forms.Label
$lblSideAIP.Location = New-Object System.Drawing.Point(14, 48)
$lblSideAIP.Size = New-Object System.Drawing.Size(76, 24)
$lblSideAIP.Font = $fontSmall
$lblSideAIP.Text = 'Side-A IP'
$form.Controls.Add($lblSideAIP)

$txtSideAIP = New-Object System.Windows.Forms.TextBox
$txtSideAIP.Location = New-Object System.Drawing.Point(92, 46)
$txtSideAIP.Size = New-Object System.Drawing.Size(150, 26)
$txtSideAIP.Font = $fontSmall
$txtSideAIP.Text = $SideAIP
$form.Controls.Add($txtSideAIP)

$lblAToZSrc = New-Object System.Windows.Forms.Label
$lblAToZSrc.Location = New-Object System.Drawing.Point(254, 48)
$lblAToZSrc.Size = New-Object System.Drawing.Size(90, 24)
$lblAToZSrc.Font = $fontSmall
$lblAToZSrc.Text = 'A->Z Src'
$form.Controls.Add($lblAToZSrc)

$txtAToZSrc = New-Object System.Windows.Forms.TextBox
$txtAToZSrc.Location = New-Object System.Drawing.Point(344, 46)
$txtAToZSrc.Size = New-Object System.Drawing.Size(78, 26)
$txtAToZSrc.Font = $fontSmall
$txtAToZSrc.Text = $SideAToSideZSourcePort
$form.Controls.Add($txtAToZSrc)

$lblAToZDst = New-Object System.Windows.Forms.Label
$lblAToZDst.Location = New-Object System.Drawing.Point(434, 48)
$lblAToZDst.Size = New-Object System.Drawing.Size(90, 24)
$lblAToZDst.Font = $fontSmall
$lblAToZDst.Text = 'A->Z Dest'
$form.Controls.Add($lblAToZDst)

$txtAToZDst = New-Object System.Windows.Forms.TextBox
$txtAToZDst.Location = New-Object System.Drawing.Point(524, 46)
$txtAToZDst.Size = New-Object System.Drawing.Size(78, 26)
$txtAToZDst.Font = $fontSmall
$txtAToZDst.Text = $SideAToSideZDestPort
$form.Controls.Add($txtAToZDst)

$lblSideZIP = New-Object System.Windows.Forms.Label
$lblSideZIP.Location = New-Object System.Drawing.Point(14, 82)
$lblSideZIP.Size = New-Object System.Drawing.Size(76, 24)
$lblSideZIP.Font = $fontSmall
$lblSideZIP.Text = 'Side-Z IP'
$form.Controls.Add($lblSideZIP)

$txtSideZIP = New-Object System.Windows.Forms.TextBox
$txtSideZIP.Location = New-Object System.Drawing.Point(92, 80)
$txtSideZIP.Size = New-Object System.Drawing.Size(150, 26)
$txtSideZIP.Font = $fontSmall
$txtSideZIP.Text = $SideZIP
$form.Controls.Add($txtSideZIP)

$lblZToASrc = New-Object System.Windows.Forms.Label
$lblZToASrc.Location = New-Object System.Drawing.Point(254, 82)
$lblZToASrc.Size = New-Object System.Drawing.Size(90, 24)
$lblZToASrc.Font = $fontSmall
$lblZToASrc.Text = 'Z->A Src'
$form.Controls.Add($lblZToASrc)

$txtZToASrc = New-Object System.Windows.Forms.TextBox
$txtZToASrc.Location = New-Object System.Drawing.Point(344, 80)
$txtZToASrc.Size = New-Object System.Drawing.Size(78, 26)
$txtZToASrc.Font = $fontSmall
$txtZToASrc.Text = $SideZToSideASourcePort
$form.Controls.Add($txtZToASrc)

$lblZToADst = New-Object System.Windows.Forms.Label
$lblZToADst.Location = New-Object System.Drawing.Point(434, 82)
$lblZToADst.Size = New-Object System.Drawing.Size(90, 24)
$lblZToADst.Font = $fontSmall
$lblZToADst.Text = 'Z->A Dest'
$form.Controls.Add($lblZToADst)

$txtZToADst = New-Object System.Windows.Forms.TextBox
$txtZToADst.Location = New-Object System.Drawing.Point(524, 80)
$txtZToADst.Size = New-Object System.Drawing.Size(78, 26)
$txtZToADst.Font = $fontSmall
$txtZToADst.Text = $SideZToSideADestPort
$form.Controls.Add($txtZToADst)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Location = New-Object System.Drawing.Point(900, 46)
$btnApply.Size = New-Object System.Drawing.Size(134, 60)
$btnApply.Font = $fontSmall
$btnApply.Text = 'Apply'
$btnApply.Anchor = 'Top,Right'
$form.Controls.Add($btnApply)

$lblChannel1 = New-Object System.Windows.Forms.Label
$lblChannel1.Location = New-Object System.Drawing.Point(14, 122)
$lblChannel1.Size = New-Object System.Drawing.Size(1020, 24)
$lblChannel1.Font = $fontSmall
$lblChannel1.Text = ''
$form.Controls.Add($lblChannel1)

$lblChannel2 = New-Object System.Windows.Forms.Label
$lblChannel2.Location = New-Object System.Drawing.Point(14, 146)
$lblChannel2.Size = New-Object System.Drawing.Size(1020, 24)
$lblChannel2.Font = $fontSmall
$lblChannel2.Text = ''
$form.Controls.Add($lblChannel2)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Location = New-Object System.Drawing.Point(14, 170)
$lblHint.Size = New-Object System.Drawing.Size(1020, 22)
$lblHint.Font = $fontSmall
$lblHint.Text = 'Enter sends. Shift+Enter inserts newline. Message input is limited to 3 lines.'
$form.Controls.Add($lblHint)

$txtHistory = New-Object System.Windows.Forms.TextBox
$txtHistory.Location = New-Object System.Drawing.Point(14, 196)
$txtHistory.Size = New-Object System.Drawing.Size(1020, 414)
$txtHistory.Multiline = $true
$txtHistory.ScrollBars = 'Vertical'
$txtHistory.ReadOnly = $true
$txtHistory.Font = $fontMain
$txtHistory.BackColor = [System.Drawing.Color]::White
$txtHistory.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($txtHistory)

$txtMessage = New-Object System.Windows.Forms.TextBox
$txtMessage.Location = New-Object System.Drawing.Point(14, 620)
$txtMessage.Size = New-Object System.Drawing.Size(870, 80)
$txtMessage.Multiline = $true
$txtMessage.AcceptsReturn = $true
$txtMessage.ScrollBars = 'Vertical'
$txtMessage.Font = $fontMain
$txtMessage.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($txtMessage)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Location = New-Object System.Drawing.Point(900, 620)
$btnSend.Size = New-Object System.Drawing.Size(134, 80)
$btnSend.Font = $fontMain
$btnSend.Text = 'Send'
$btnSend.Anchor = 'Bottom,Right'
$form.Controls.Add($btnSend)

$status = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Spring = $true
$statusLabel.TextAlign = 'MiddleLeft'
$statusLabel.Text = 'Starting...'
[void]$status.Items.Add($statusLabel)
$form.Controls.Add($status)

$probeTimer = New-Object System.Windows.Forms.Timer
$probeTimer.Interval = 10000

function Add-ChatLine {
    param(
        [string]$Prefix,
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] $Prefix $Message"

    if ([string]::IsNullOrWhiteSpace($txtHistory.Text)) {
        $txtHistory.Text = $line
    } else {
        $txtHistory.AppendText([Environment]::NewLine + $line)
    }

    $txtHistory.SelectionStart = $txtHistory.TextLength
    $txtHistory.ScrollToCaret()
}

function Get-LineCount {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return 1
    }

    return ([regex]::Split($Text, "`r?`n")).Count
}

$script:isTrimmingInput = $false
$txtMessage.Add_TextChanged({
    if ($script:isTrimmingInput) {
        return
    }

    if ((Get-LineCount $txtMessage.Text) -gt $maxInputLines) {
        $script:isTrimmingInput = $true
        try {
            $lines = [regex]::Split($txtMessage.Text, "`r?`n")
            $txtMessage.Text = ($lines[0..($maxInputLines - 1)] -join [Environment]::NewLine)
            $txtMessage.SelectionStart = $txtMessage.TextLength
        } finally {
            $script:isTrimmingInput = $false
        }
    }
})

$script:currentSideAIP = $SideAIP
$script:currentSideZIP = $SideZIP
$script:currentAToZSourcePort = $SideAToSideZSourcePort
$script:currentAToZDestPort = $SideAToSideZDestPort
$script:currentZToASourcePort = $SideZToSideASourcePort
$script:currentZToADestPort = $SideZToSideADestPort
$script:sendClient = $null
$script:sendStream = $null
$script:sendConnectClient = $null
$script:sendConnectAsync = $null
$script:sendConnectStartedUtc = [DateTime]::MinValue
$script:nextSendConnectUtc = [DateTime]::MinValue
$script:recvListener = $null
$script:recvClient = $null
$script:recvStream = $null
$script:recvBuffer = New-Object System.Collections.Generic.List[byte]
$script:lastRxUtc = [DateTime]::UtcNow
$script:lastAutoRecoverUtc = [DateTime]::MinValue

function Update-NetworkLabels {
    $lblChannel1.Text = "Channel Z -> A : side-z $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> side-a $($script:currentSideAIP)`:$($script:currentZToADestPort)"
    $lblChannel2.Text = "Channel A -> Z : side-a $($script:currentSideAIP)`:$($script:currentAToZSourcePort) -> side-z $($script:currentSideZIP)`:$($script:currentAToZDestPort)"

    $sendState = 'Disconnected'
    if (($null -ne $script:sendClient) -and $script:sendClient.Connected) {
        $sendState = 'Connected'
    } elseif ($null -ne $script:sendConnectAsync) {
        $sendState = 'Connecting'
    }

    $recvState = 'Waiting'
    if ($null -ne $script:recvClient) {
        $recvState = 'Connected'
    }

    $statusLabel.Text = "Send(Z->A): $sendState $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> $($script:currentSideAIP)`:$($script:currentZToADestPort) | Recv(A->Z): $recvState $($script:currentSideZIP)`:$($script:currentAToZDestPort)"
}

function Close-SendClient {
    if ($null -ne $script:sendStream) {
        try { $script:sendStream.Close() } catch {}
        $script:sendStream = $null
    }

    if ($null -ne $script:sendClient) {
        try { $script:sendClient.Close() } catch {}
        $script:sendClient = $null
    }
}

function Close-PendingSendConnect {
    if ($null -ne $script:sendConnectClient) {
        try { $script:sendConnectClient.Close() } catch {}
        $script:sendConnectClient = $null
    }

    $script:sendConnectAsync = $null
    $script:sendConnectStartedUtc = [DateTime]::MinValue
}

function Close-RecvClient {
    if ($null -ne $script:recvStream) {
        try { $script:recvStream.Close() } catch {}
        $script:recvStream = $null
    }

    if ($null -ne $script:recvClient) {
        try { $script:recvClient.Close() } catch {}
        $script:recvClient = $null
    }

    $script:recvBuffer = New-Object System.Collections.Generic.List[byte]
}

function Close-TcpObjects {
    Close-PendingSendConnect
    Close-SendClient
    Close-RecvClient

    if ($null -ne $script:recvListener) {
        try { $script:recvListener.Stop() } catch {}
        $script:recvListener = $null
    }
}

function New-BoundTcpClient {
    param(
        [System.Net.IPAddress]$LocalAddress,
        [int]$LocalPort
    )

    $client = New-Object System.Net.Sockets.TcpClient($LocalAddress.AddressFamily)
    $client.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $client.Client.ExclusiveAddressUse = $false
    $client.Client.Bind((New-Object System.Net.IPEndPoint($LocalAddress, $LocalPort)))
    return $client
}

function Start-SendConnect {
    if ($null -ne $script:sendClient) {
        return
    }
    if ($null -ne $script:sendConnectAsync) {
        return
    }
    if ([DateTime]::UtcNow -lt $script:nextSendConnectUtc) {
        return
    }

    try {
        $sideAAddress = [System.Net.IPAddress]::Parse($script:currentSideAIP)
        $sideZAddress = [System.Net.IPAddress]::Parse($script:currentSideZIP)
        $script:sendConnectClient = New-BoundTcpClient -LocalAddress $sideZAddress -LocalPort $script:currentZToASourcePort
        $script:sendConnectAsync = $script:sendConnectClient.Client.BeginConnect($sideAAddress, $script:currentZToADestPort, $null, $null)
        $script:sendConnectStartedUtc = [DateTime]::UtcNow
        Update-NetworkLabels
    } catch {
        Close-PendingSendConnect
        $script:nextSendConnectUtc = [DateTime]::UtcNow.AddMilliseconds($connectRetryIntervalMs)
        Add-ChatLine -Prefix '[Error]' -Message ("Connect start failed: " + $_.Exception.Message)
        Update-NetworkLabels
    }
}

function Complete-SendConnectIfReady {
    if ($null -eq $script:sendConnectAsync) {
        return
    }

    $elapsedMs = ([DateTime]::UtcNow - $script:sendConnectStartedUtc).TotalMilliseconds
    if ((-not $script:sendConnectAsync.IsCompleted) -and ($elapsedMs -lt $connectTimeoutMs)) {
        return
    }

    if ((-not $script:sendConnectAsync.IsCompleted) -and ($elapsedMs -ge $connectTimeoutMs)) {
        Close-PendingSendConnect
        $script:nextSendConnectUtc = [DateTime]::UtcNow.AddMilliseconds($connectRetryIntervalMs)
        Add-ChatLine -Prefix '[System]' -Message 'TCP connect timed out; retrying.'
        Update-NetworkLabels
        return
    }

    try {
        $script:sendConnectClient.Client.EndConnect($script:sendConnectAsync)
        $script:sendClient = $script:sendConnectClient
        $script:sendStream = $script:sendClient.GetStream()
        $script:sendStream.ReadTimeout = 1
        $script:sendStream.WriteTimeout = 5000
        $script:sendConnectClient = $null
        $script:sendConnectAsync = $null
        $script:sendConnectStartedUtc = [DateTime]::MinValue
        Add-ChatLine -Prefix '[System]' -Message 'TCP send channel connected.'
    } catch {
        Close-PendingSendConnect
        $script:nextSendConnectUtc = [DateTime]::UtcNow.AddMilliseconds($connectRetryIntervalMs)
        Add-ChatLine -Prefix '[Error]' -Message ("Connect failed: " + $_.Exception.Message)
    }

    Update-NetworkLabels
}

function Accept-RecvClientIfPending {
    if ($null -eq $script:recvListener) {
        return
    }

    try {
        while ($script:recvListener.Pending()) {
            $nextClient = $script:recvListener.AcceptTcpClient()
            $nextClient.NoDelay = $true
            $nextClient.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::KeepAlive, $true)
            $nextStream = $nextClient.GetStream()
            $nextStream.ReadTimeout = 1
            Close-RecvClient
            $script:recvClient = $nextClient
            $script:recvStream = $nextStream
            $script:lastRxUtc = [DateTime]::UtcNow
            Add-ChatLine -Prefix '[System]' -Message ("TCP receive channel connected from " + $nextClient.Client.RemoteEndPoint.ToString())
            Update-NetworkLabels
        }
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Accept failed: " + $_.Exception.Message)
    }
}

function Write-FramedMessage {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [byte[]]$Payload
    )

    $lengthBytes = [System.BitConverter]::GetBytes([int]$Payload.Length)
    $Stream.Write($lengthBytes, 0, $lengthBytes.Length)
    if ($Payload.Length -gt 0) {
        $Stream.Write($Payload, 0, $Payload.Length)
    }
    $Stream.Flush()
}

function Read-AvailableBytes {
    if (($null -eq $script:recvClient) -or ($null -eq $script:recvStream)) {
        return
    }

    try {
        $buffer = New-Object byte[] 4096
        while ($script:recvStream.DataAvailable) {
            $read = $script:recvStream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) {
                throw 'Remote peer closed the receive channel.'
            }

            for ($i = 0; $i -lt $read; $i++) {
                [void]$script:recvBuffer.Add($buffer[$i])
            }
        }

        if (($null -ne $script:recvClient) -and $script:recvClient.Client.Poll(1, [System.Net.Sockets.SelectMode]::SelectRead) -and ($script:recvClient.Client.Available -eq 0)) {
            throw 'Remote peer closed the receive channel.'
        }
    } catch {
        Close-RecvClient
        Add-ChatLine -Prefix '[System]' -Message ("Receive channel closed: " + $_.Exception.Message)
        Update-NetworkLabels
    }
}

function Process-ReceiveFrames {
    while ($script:recvBuffer.Count -ge 4) {
        $frameArray = $script:recvBuffer.ToArray()
        $payloadLength = [System.BitConverter]::ToInt32($frameArray, 0)
        if ($payloadLength -lt 0) {
            Close-RecvClient
            Add-ChatLine -Prefix '[Error]' -Message 'Receive channel carried an invalid frame length.'
            Update-NetworkLabels
            return
        }
        if ($script:recvBuffer.Count -lt (4 + $payloadLength)) {
            return
        }

        $payloadBytes = New-Object byte[] $payloadLength
        if ($payloadLength -gt 0) {
            [Array]::Copy($frameArray, 4, $payloadBytes, 0, $payloadLength)
        }
        $script:recvBuffer.RemoveRange(0, 4 + $payloadLength)

        $msg = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $script:lastRxUtc = [DateTime]::UtcNow
        $endpoint = $script:recvClient.Client.RemoteEndPoint
        $endpointText = $endpoint.ToString()
        $isExpectedPeer = Test-ExpectedPeer -Endpoint $endpoint -ExpectedPort $script:currentAToZSourcePort -ExpectedIP $script:currentSideAIP

        if ($msg -eq $remoteProbePayloadText) {
            if ($isExpectedPeer) {
                Add-ChatLine -Prefix "[Probe RX $endpointText A->Z]" -Message $msg
            } else {
                Add-ChatLine -Prefix "[Probe RX Unverified $endpointText A->Z]" -Message $msg
            }
        } else {
            if ($isExpectedPeer) {
                Add-ChatLine -Prefix "[$endpointText A->Z]" -Message $msg
            } else {
                Add-ChatLine -Prefix "[Unverified $endpointText A->Z]" -Message $msg
            }
        }
    }
}

function Initialize-Network {
    param(
        [string]$NextSideAIP,
        [string]$NextSideZIP,
        [int]$NextAToZSourcePort,
        [int]$NextAToZDestPort,
        [int]$NextZToASourcePort,
        [int]$NextZToADestPort
    )

    [void][System.Net.IPAddress]::Parse($NextSideAIP)
    $sideZAddress = [System.Net.IPAddress]::Parse($NextSideZIP)

    $nextRecvListener = New-Object System.Net.Sockets.TcpListener($sideZAddress, $NextAToZDestPort)
    $nextRecvListener.Server.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $nextRecvListener.Server.ExclusiveAddressUse = $false
    $nextRecvListener.Start()

    Close-TcpObjects

    $script:currentSideAIP = $NextSideAIP
    $script:currentSideZIP = $NextSideZIP
    $script:currentAToZSourcePort = $NextAToZSourcePort
    $script:currentAToZDestPort = $NextAToZDestPort
    $script:currentZToASourcePort = $NextZToASourcePort
    $script:currentZToADestPort = $NextZToADestPort
    $script:recvListener = $nextRecvListener
    $script:recvBuffer = New-Object System.Collections.Generic.List[byte]
    $script:lastRxUtc = [DateTime]::UtcNow
    $script:lastAutoRecoverUtc = [DateTime]::MinValue
    $script:nextSendConnectUtc = [DateTime]::MinValue

    Start-SendConnect
    Update-NetworkLabels
}

function Parse-PortOrThrow {
    param(
        [string]$Text,
        [string]$FieldName
    )

    $parsed = 0
    if (-not [int]::TryParse($Text, [ref]$parsed)) {
        throw "$FieldName must be a whole number."
    }
    if (($parsed -lt 1) -or ($parsed -gt 65535)) {
        throw "$FieldName must be between 1 and 65535."
    }
    return $parsed
}

function Test-ExpectedPeer {
    param(
        [System.Net.IPEndPoint]$Endpoint,
        [int]$ExpectedPort,
        [string]$ExpectedIP
    )

    if ($null -eq $Endpoint) {
        return $false
    }

    if ($Endpoint.Port -ne $ExpectedPort) {
        return $false
    }

    if (($ExpectedIP -eq '0.0.0.0') -or ($ExpectedIP -eq '::')) {
        return $true
    }

    return ($Endpoint.Address.ToString() -eq $ExpectedIP)
}

function Apply-NetworkSettings {
    try {
        $nextSideAIP = $txtSideAIP.Text.Trim()
        $nextSideZIP = $txtSideZIP.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($nextSideAIP)) {
            throw 'Side-A IP is required.'
        }
        if ([string]::IsNullOrWhiteSpace($nextSideZIP)) {
            throw 'Side-Z IP is required.'
        }

        $nextAToZSourcePort = Parse-PortOrThrow -Text $txtAToZSrc.Text.Trim() -FieldName 'A->Z Source Port'
        $nextAToZDestPort = Parse-PortOrThrow -Text $txtAToZDst.Text.Trim() -FieldName 'A->Z Destination Port'
        $nextZToASourcePort = Parse-PortOrThrow -Text $txtZToASrc.Text.Trim() -FieldName 'Z->A Source Port'
        $nextZToADestPort = Parse-PortOrThrow -Text $txtZToADst.Text.Trim() -FieldName 'Z->A Destination Port'

        Initialize-Network -NextSideAIP $nextSideAIP -NextSideZIP $nextSideZIP -NextAToZSourcePort $nextAToZSourcePort -NextAToZDestPort $nextAToZDestPort -NextZToASourcePort $nextZToASourcePort -NextZToADestPort $nextZToADestPort
        Add-ChatLine -Prefix '[System]' -Message 'Network settings applied.'
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Apply failed: " + $_.Exception.Message)
    }
}

Initialize-Network -NextSideAIP $SideAIP -NextSideZIP $SideZIP -NextAToZSourcePort $SideAToSideZSourcePort -NextAToZDestPort $SideAToSideZDestPort -NextZToASourcePort $SideZToSideASourcePort -NextZToADestPort $SideZToSideADestPort
Add-ChatLine -Prefix '[System]' -Message "Initialized as $DisplayName."

$receiveTimer = New-Object System.Windows.Forms.Timer
$receiveTimer.Interval = 70
$receiveTimer.Add_Tick({
    try {
        Complete-SendConnectIfReady
        Start-SendConnect
        Accept-RecvClientIfPending
        Read-AvailableBytes
        Process-ReceiveFrames
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Receive loop failed: " + $_.Exception.Message)
    }
})

$watchdogTimer = New-Object System.Windows.Forms.Timer
$watchdogTimer.Interval = 15000
$watchdogTimer.Add_Tick({
    try {
        Complete-SendConnectIfReady
        Start-SendConnect
        Accept-RecvClientIfPending

        $nowUtc = [DateTime]::UtcNow
        $secondsSinceRx = ($nowUtc - $script:lastRxUtc).TotalSeconds
        $secondsSinceRecover = ($nowUtc - $script:lastAutoRecoverUtc).TotalSeconds

        if (($secondsSinceRx -ge 45) -and ($secondsSinceRecover -ge 45)) {
            $script:lastAutoRecoverUtc = $nowUtc
            Add-ChatLine -Prefix '[System]' -Message "No inbound traffic for $([int]$secondsSinceRx)s; auto-reinitializing TCP channels."
            Initialize-Network -NextSideAIP $script:currentSideAIP -NextSideZIP $script:currentSideZIP -NextAToZSourcePort $script:currentAToZSourcePort -NextAToZDestPort $script:currentAToZDestPort -NextZToASourcePort $script:currentZToASourcePort -NextZToADestPort $script:currentZToADestPort
            Send-ProbePacket
        }
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Auto-recover failed: " + $_.Exception.Message)
    }
})

function Send-Message {
    $text = $txtMessage.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return
    }

    try {
        if (($null -eq $script:sendClient) -or (-not $script:sendClient.Connected) -or ($null -eq $script:sendStream)) {
            throw 'TCP send channel is not connected yet.'
        }
        $payload = [System.Text.Encoding]::UTF8.GetBytes($text)
        Write-FramedMessage -Stream $script:sendStream -Payload $payload
        Add-ChatLine -Prefix "[$DisplayName Z->A]" -Message $text
        $txtMessage.Clear()
        $txtMessage.Focus()
    } catch {
        Close-SendClient
        $script:nextSendConnectUtc = [DateTime]::UtcNow
        Add-ChatLine -Prefix '[Error]' -Message ("Send failed: " + $_.Exception.Message)
        Update-NetworkLabels
    }
}

function Send-ProbePacket {
    try {
        if (($null -eq $script:sendClient) -or (-not $script:sendClient.Connected) -or ($null -eq $script:sendStream)) {
            return
        }
        Write-FramedMessage -Stream $script:sendStream -Payload $probePayloadBytes
        Add-ChatLine -Prefix '[Probe TX]' -Message $probePayloadText
    } catch {
        Close-SendClient
        $script:nextSendConnectUtc = [DateTime]::UtcNow
        Add-ChatLine -Prefix '[Error]' -Message ("Probe send failed: " + $_.Exception.Message)
        Update-NetworkLabels
    }
}

$btnSend.Add_Click({ Send-Message })
$btnApply.Add_Click({ Apply-NetworkSettings })
$probeTimer.Add_Tick({ Send-ProbePacket })
$txtMessage.Add_KeyDown({
    param($sender, $e)

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        if ($e.Shift) {
            if ((Get-LineCount $txtMessage.Text) -ge $maxInputLines) {
                $e.SuppressKeyPress = $true
            }
            return
        }

        $e.SuppressKeyPress = $true
        Send-Message
    }
})

$form.Add_Shown({
    $txtMessage.Focus()
    $probeTimer.Start()
    $receiveTimer.Start()
    $watchdogTimer.Start()
    Send-ProbePacket
})

$form.Add_FormClosing({
    $probeTimer.Stop()
    $receiveTimer.Stop()
    $watchdogTimer.Stop()
    Close-TcpObjects
})

[void]$form.ShowDialog()
