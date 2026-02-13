param(
    [string]$LocalIP = '0.0.0.0',
    [string]$RemoteIP = '127.0.0.1',

    [int]$AtoZSourcePort = 7000,
    [int]$AtoZDestPort = 7000,
    [int]$ZtoASourcePort = 7001,
    [int]$ZtoADestPort = 7001,

    [string]$DisplayName = 'Side A'
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$maxInputLines = 3

$fontMain = New-Object System.Drawing.Font('Segoe UI', 10)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 9)

$form = New-Object System.Windows.Forms.Form
$form.Text = "UDP P2P Chat - $DisplayName"
$form.Size = New-Object System.Drawing.Size(860, 620)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(760, 520)
$form.KeyPreview = $true

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(14, 12)
$lblTitle.Size = New-Object System.Drawing.Size(820, 24)
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
$lblTitle.Text = "Peer-to-Peer UDP Chat ($DisplayName)"
$form.Controls.Add($lblTitle)

$lblLocalIP = New-Object System.Windows.Forms.Label
$lblLocalIP.Location = New-Object System.Drawing.Point(14, 42)
$lblLocalIP.Size = New-Object System.Drawing.Size(56, 20)
$lblLocalIP.Font = $fontSmall
$lblLocalIP.Text = 'Local IP'
$form.Controls.Add($lblLocalIP)

$txtLocalIP = New-Object System.Windows.Forms.TextBox
$txtLocalIP.Location = New-Object System.Drawing.Point(72, 40)
$txtLocalIP.Size = New-Object System.Drawing.Size(120, 24)
$txtLocalIP.Font = $fontSmall
$txtLocalIP.Text = $LocalIP
$form.Controls.Add($txtLocalIP)

$lblRemoteIP = New-Object System.Windows.Forms.Label
$lblRemoteIP.Location = New-Object System.Drawing.Point(204, 68)
$lblRemoteIP.Size = New-Object System.Drawing.Size(64, 20)
$lblRemoteIP.Font = $fontSmall
$lblRemoteIP.Text = 'Remote IP'
$form.Controls.Add($lblRemoteIP)

$txtRemoteIP = New-Object System.Windows.Forms.TextBox
$txtRemoteIP.Location = New-Object System.Drawing.Point(272, 66)
$txtRemoteIP.Size = New-Object System.Drawing.Size(120, 24)
$txtRemoteIP.Font = $fontSmall
$txtRemoteIP.Text = $RemoteIP
$form.Controls.Add($txtRemoteIP)

$lblAtoZSource = New-Object System.Windows.Forms.Label
$lblAtoZSource.Location = New-Object System.Drawing.Point(204, 42)
$lblAtoZSource.Size = New-Object System.Drawing.Size(78, 20)
$lblAtoZSource.Font = $fontSmall
$lblAtoZSource.Text = 'A->Z Src'
$form.Controls.Add($lblAtoZSource)

$txtAtoZSourcePort = New-Object System.Windows.Forms.TextBox
$txtAtoZSourcePort.Location = New-Object System.Drawing.Point(282, 40)
$txtAtoZSourcePort.Size = New-Object System.Drawing.Size(64, 24)
$txtAtoZSourcePort.Font = $fontSmall
$txtAtoZSourcePort.Text = $AtoZSourcePort
$form.Controls.Add($txtAtoZSourcePort)

$lblAtoZDest = New-Object System.Windows.Forms.Label
$lblAtoZDest.Location = New-Object System.Drawing.Point(356, 42)
$lblAtoZDest.Size = New-Object System.Drawing.Size(78, 20)
$lblAtoZDest.Font = $fontSmall
$lblAtoZDest.Text = 'A->Z Dest'
$form.Controls.Add($lblAtoZDest)

$txtAtoZDestPort = New-Object System.Windows.Forms.TextBox
$txtAtoZDestPort.Location = New-Object System.Drawing.Point(434, 40)
$txtAtoZDestPort.Size = New-Object System.Drawing.Size(64, 24)
$txtAtoZDestPort.Font = $fontSmall
$txtAtoZDestPort.Text = $AtoZDestPort
$form.Controls.Add($txtAtoZDestPort)

$lblZtoASource = New-Object System.Windows.Forms.Label
$lblZtoASource.Location = New-Object System.Drawing.Point(14, 68)
$lblZtoASource.Size = New-Object System.Drawing.Size(78, 20)
$lblZtoASource.Font = $fontSmall
$lblZtoASource.Text = 'Z->A Src'
$form.Controls.Add($lblZtoASource)

$txtZtoASourcePort = New-Object System.Windows.Forms.TextBox
$txtZtoASourcePort.Location = New-Object System.Drawing.Point(92, 66)
$txtZtoASourcePort.Size = New-Object System.Drawing.Size(64, 24)
$txtZtoASourcePort.Font = $fontSmall
$txtZtoASourcePort.Text = $ZtoASourcePort
$form.Controls.Add($txtZtoASourcePort)

$lblZtoADest = New-Object System.Windows.Forms.Label
$lblZtoADest.Location = New-Object System.Drawing.Point(166, 68)
$lblZtoADest.Size = New-Object System.Drawing.Size(78, 20)
$lblZtoADest.Font = $fontSmall
$lblZtoADest.Text = 'Z->A Dest'
$form.Controls.Add($lblZtoADest)

$txtZtoADestPort = New-Object System.Windows.Forms.TextBox
$txtZtoADestPort.Location = New-Object System.Drawing.Point(90, 66)
$txtZtoADestPort.Size = New-Object System.Drawing.Size(64, 24)
$txtZtoADestPort.Font = $fontSmall
$txtZtoADestPort.Text = $ZtoADestPort
$form.Controls.Add($txtZtoADestPort)

$btnApplyNetwork = New-Object System.Windows.Forms.Button
$btnApplyNetwork.Location = New-Object System.Drawing.Point(724, 40)
$btnApplyNetwork.Size = New-Object System.Drawing.Size(110, 50)
$btnApplyNetwork.Font = $fontSmall
$btnApplyNetwork.Text = 'Apply'
$btnApplyNetwork.Anchor = 'Top,Right'
$form.Controls.Add($btnApplyNetwork)

$lblChannel1 = New-Object System.Windows.Forms.Label
$lblChannel1.Location = New-Object System.Drawing.Point(14, 96)
$lblChannel1.Size = New-Object System.Drawing.Size(820, 20)
$lblChannel1.Font = $fontSmall
$lblChannel1.Text = ''
$form.Controls.Add($lblChannel1)

$lblChannel2 = New-Object System.Windows.Forms.Label
$lblChannel2.Location = New-Object System.Drawing.Point(14, 116)
$lblChannel2.Size = New-Object System.Drawing.Size(820, 20)
$lblChannel2.Font = $fontSmall
$lblChannel2.Text = ''
$form.Controls.Add($lblChannel2)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Location = New-Object System.Drawing.Point(14, 136)
$lblHint.Size = New-Object System.Drawing.Size(820, 18)
$lblHint.Font = $fontSmall
$lblHint.Text = "Enter sends. Shift+Enter inserts newline. Message input is limited to 3 lines. Apply updates networking."
$form.Controls.Add($lblHint)

$txtHistory = New-Object System.Windows.Forms.TextBox
$txtHistory.Location = New-Object System.Drawing.Point(14, 160)
$txtHistory.Size = New-Object System.Drawing.Size(820, 296)
$txtHistory.Multiline = $true
$txtHistory.ScrollBars = 'Vertical'
$txtHistory.ReadOnly = $true
$txtHistory.Font = $fontMain
$txtHistory.BackColor = [System.Drawing.Color]::White
$txtHistory.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($txtHistory)

$txtMessage = New-Object System.Windows.Forms.TextBox
$txtMessage.Location = New-Object System.Drawing.Point(14, 468)
$txtMessage.Size = New-Object System.Drawing.Size(700, 64)
$txtMessage.Multiline = $true
$txtMessage.AcceptsReturn = $true
$txtMessage.ScrollBars = 'Vertical'
$txtMessage.Font = $fontMain
$txtMessage.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($txtMessage)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Location = New-Object System.Drawing.Point(724, 468)
$btnSend.Size = New-Object System.Drawing.Size(110, 64)
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

$script:currentLocalIP = $LocalIP
$script:currentRemoteIP = $RemoteIP
$script:currentAtoZSourcePort = $AtoZSourcePort
$script:currentAtoZDestPort = $AtoZDestPort
$script:currentZtoASourcePort = $ZtoASourcePort
$script:currentZtoADestPort = $ZtoADestPort
$script:sendEndpoint = $null
$script:sendUdp = $null
$script:recvUdp = $null

function Update-NetworkLabels {
    $lblChannel1.Text = "Channel A -> Z : local $($script:currentLocalIP)`:$($script:currentAtoZSourcePort) -> remote $($script:currentRemoteIP)`:$($script:currentAtoZDestPort)"
    $lblChannel2.Text = "Channel Z -> A : remote $($script:currentRemoteIP)`:$($script:currentZtoASourcePort) -> local $($script:currentLocalIP)`:$($script:currentZtoADestPort)"
    $statusLabel.Text = "Send(A->Z): $($script:currentLocalIP)`:$($script:currentAtoZSourcePort) -> $($script:currentRemoteIP)`:$($script:currentAtoZDestPort) | Recv(Z->A): $($script:currentLocalIP)`:$($script:currentZtoADestPort)"
}

function Close-UdpClients {
    if ($null -ne $script:sendUdp) {
        try { $script:sendUdp.Close() } catch {}
        $script:sendUdp = $null
    }

    if ($null -ne $script:recvUdp) {
        try { $script:recvUdp.Close() } catch {}
        $script:recvUdp = $null
    }
}

function Initialize-Network {
    param(
        [string]$NextLocalIP,
        [string]$NextRemoteIP,
        [int]$NextAtoZSourcePort,
        [int]$NextAtoZDestPort,
        [int]$NextZtoASourcePort,
        [int]$NextZtoADestPort
    )

    $localAddress = [System.Net.IPAddress]::Parse($NextLocalIP)
    $nextRemoteAddress = [System.Net.IPAddress]::Parse($NextRemoteIP)

    $nextSendUdp = New-Object System.Net.Sockets.UdpClient
    $nextSendUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $nextSendUdp.ExclusiveAddressUse = $false
    $nextSendUdp.Client.Bind((New-Object System.Net.IPEndPoint($localAddress, $NextAtoZSourcePort)))

    $nextRecvUdp = New-Object System.Net.Sockets.UdpClient
    $nextRecvUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $nextRecvUdp.ExclusiveAddressUse = $false
    $nextRecvUdp.Client.Bind((New-Object System.Net.IPEndPoint($localAddress, $NextZtoADestPort)))

    Close-UdpClients

    $script:currentLocalIP = $NextLocalIP
    $script:currentRemoteIP = $NextRemoteIP
    $script:currentAtoZSourcePort = $NextAtoZSourcePort
    $script:currentAtoZDestPort = $NextAtoZDestPort
    $script:currentZtoASourcePort = $NextZtoASourcePort
    $script:currentZtoADestPort = $NextZtoADestPort
    $script:sendUdp = $nextSendUdp
    $script:recvUdp = $nextRecvUdp
    $script:sendEndpoint = New-Object System.Net.IPEndPoint($nextRemoteAddress, $script:currentAtoZDestPort)

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

function Apply-NetworkSettings {
    try {
        $nextLocalIP = $txtLocalIP.Text.Trim()
        $nextRemoteIP = $txtRemoteIP.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($nextLocalIP)) {
            throw 'Local IP is required.'
        }
        if ([string]::IsNullOrWhiteSpace($nextRemoteIP)) {
            throw 'Remote IP is required.'
        }

        $nextAtoZSourcePort = Parse-PortOrThrow -Text $txtAtoZSourcePort.Text.Trim() -FieldName 'A->Z Source Port'
        $nextAtoZDestPort = Parse-PortOrThrow -Text $txtAtoZDestPort.Text.Trim() -FieldName 'A->Z Destination Port'
        $nextZtoASourcePort = Parse-PortOrThrow -Text $txtZtoASourcePort.Text.Trim() -FieldName 'Z->A Source Port'
        $nextZtoADestPort = Parse-PortOrThrow -Text $txtZtoADestPort.Text.Trim() -FieldName 'Z->A Destination Port'

        Initialize-Network -NextLocalIP $nextLocalIP -NextRemoteIP $nextRemoteIP -NextAtoZSourcePort $nextAtoZSourcePort -NextAtoZDestPort $nextAtoZDestPort -NextZtoASourcePort $nextZtoASourcePort -NextZtoADestPort $nextZtoADestPort
        Add-ChatLine -Prefix '[System]' -Message "Network settings applied."
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Apply failed: " + $_.Exception.Message)
    }
}

Initialize-Network -NextLocalIP $LocalIP -NextRemoteIP $RemoteIP -NextAtoZSourcePort $AtoZSourcePort -NextAtoZDestPort $AtoZDestPort -NextZtoASourcePort $ZtoASourcePort -NextZtoADestPort $ZtoADestPort
Add-ChatLine -Prefix '[System]' -Message "Initialized as $DisplayName."

$receiveWorker = New-Object System.ComponentModel.BackgroundWorker
$receiveWorker.WorkerSupportsCancellation = $true

$receiveWorker.add_DoWork({
    param($sender, $e)

    $anyEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

    while (-not $sender.CancellationPending) {
        try {
            if (($null -ne $script:recvUdp) -and ($script:recvUdp.Available -gt 0)) {
                $bytes = $script:recvUdp.Receive([ref]$anyEndpoint)
                $msg = [System.Text.Encoding]::UTF8.GetString($bytes)

                if (($anyEndpoint.Port -eq $script:currentZtoASourcePort) -and ($anyEndpoint.Address.ToString() -eq $script:currentRemoteIP)) {
                    $form.BeginInvoke([Action]{
                        Add-ChatLine -Prefix "[$($anyEndpoint.ToString()) Z->A]" -Message $msg
                    }) | Out-Null
                }
            } else {
                Start-Sleep -Milliseconds 70
            }
        } catch {
            if (-not $sender.CancellationPending) {
                $err = $_.Exception.Message
                $form.BeginInvoke([Action]{
                    Add-ChatLine -Prefix '[Error]' -Message "Receive failed: $err"
                }) | Out-Null
            }
        }
    }
})

function Send-Message {
    $text = $txtMessage.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return
    }

    try {
        if (($null -eq $script:sendUdp) -or ($null -eq $script:sendEndpoint)) {
            throw 'Network is not initialized.'
        }
        $payload = [System.Text.Encoding]::UTF8.GetBytes($text)
        [void]$script:sendUdp.Send($payload, $payload.Length, $script:sendEndpoint)
        Add-ChatLine -Prefix "[$DisplayName A->Z]" -Message $text
        $txtMessage.Clear()
        $txtMessage.Focus()
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Send failed: " + $_.Exception.Message)
    }
}

$btnSend.Add_Click({ Send-Message })
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
    $btnApplyNetwork.Focus()
    $txtMessage.Focus()
    if (-not $receiveWorker.IsBusy) {
        $receiveWorker.RunWorkerAsync()
    }
})

$btnApplyNetwork.Add_Click({ Apply-NetworkSettings })

$form.Add_FormClosing({
    if ($receiveWorker.IsBusy) {
        $receiveWorker.CancelAsync()
    }

    Close-UdpClients
})

[void]$form.ShowDialog()
