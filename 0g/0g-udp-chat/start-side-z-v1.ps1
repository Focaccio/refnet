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
$probePayloadText = '5555544444333332222211111'
$probePayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($probePayloadText)

$fontMain = New-Object System.Drawing.Font('Segoe UI', 12)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 10)
$fontTitle = New-Object System.Drawing.Font('Segoe UI Semibold', 13)

$form = New-Object System.Windows.Forms.Form
$form.Text = "UDP P2P Chat - $DisplayName"
$form.Size = New-Object System.Drawing.Size(1080, 780)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(920, 640)
$form.KeyPreview = $true
$form.AutoScaleMode = 'Dpi'

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(14, 12)
$lblTitle.Size = New-Object System.Drawing.Size(1020, 28)
$lblTitle.Font = $fontTitle
$lblTitle.Text = "Peer-to-Peer UDP Chat ($DisplayName)"
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
$probeTimer.Interval = 30000

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
$script:sendEndpoint = $null
$script:sendUdp = $null
$script:recvUdp = $null

function Update-NetworkLabels {
    $lblChannel1.Text = "Channel Z -> A : side-z $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> side-a $($script:currentSideAIP)`:$($script:currentZToADestPort)"
    $lblChannel2.Text = "Channel A -> Z : side-a $($script:currentSideAIP)`:$($script:currentAToZSourcePort) -> side-z $($script:currentSideZIP)`:$($script:currentAToZDestPort)"
    $statusLabel.Text = "Send(Z->A): $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> $($script:currentSideAIP)`:$($script:currentZToADestPort) | Recv(A->Z): $($script:currentSideZIP)`:$($script:currentAToZDestPort)"
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
        [string]$NextSideAIP,
        [string]$NextSideZIP,
        [int]$NextAToZSourcePort,
        [int]$NextAToZDestPort,
        [int]$NextZToASourcePort,
        [int]$NextZToADestPort
    )

    $sideAAddress = [System.Net.IPAddress]::Parse($NextSideAIP)
    $sideZAddress = [System.Net.IPAddress]::Parse($NextSideZIP)

    $nextSendUdp = New-Object System.Net.Sockets.UdpClient
    $nextSendUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $nextSendUdp.ExclusiveAddressUse = $false
    $nextSendUdp.Client.Bind((New-Object System.Net.IPEndPoint($sideZAddress, $NextZToASourcePort)))

    $nextRecvUdp = New-Object System.Net.Sockets.UdpClient
    $nextRecvUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
    $nextRecvUdp.ExclusiveAddressUse = $false
    $nextRecvUdp.Client.Bind((New-Object System.Net.IPEndPoint($sideZAddress, $NextAToZDestPort)))

    Close-UdpClients

    $script:currentSideAIP = $NextSideAIP
    $script:currentSideZIP = $NextSideZIP
    $script:currentAToZSourcePort = $NextAToZSourcePort
    $script:currentAToZDestPort = $NextAToZDestPort
    $script:currentZToASourcePort = $NextZToASourcePort
    $script:currentZToADestPort = $NextZToADestPort
    $script:sendUdp = $nextSendUdp
    $script:recvUdp = $nextRecvUdp
    $script:sendEndpoint = New-Object System.Net.IPEndPoint($sideAAddress, $script:currentZToADestPort)

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

                if (Test-ExpectedPeer -Endpoint $anyEndpoint -ExpectedPort $script:currentAToZSourcePort -ExpectedIP $script:currentSideAIP) {
                    $form.BeginInvoke([Action]{
                        if ($msg -eq $probePayloadText) { Add-ChatLine -Prefix "[Probe RX $($anyEndpoint.ToString()) A->Z]" -Message $msg } else { Add-ChatLine -Prefix "[$($anyEndpoint.ToString()) A->Z]" -Message $msg }
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
        Add-ChatLine -Prefix "[$DisplayName Z->A]" -Message $text
        $txtMessage.Clear()
        $txtMessage.Focus()
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Send failed: " + $_.Exception.Message)
    }
}

function Send-ProbePacket {
    try {
        if (($null -eq $script:sendUdp) -or ($null -eq $script:sendEndpoint)) {
            return
        }
        [void]$script:sendUdp.Send($probePayloadBytes, $probePayloadBytes.Length, $script:sendEndpoint)
        Add-ChatLine -Prefix '[Probe TX]' -Message $probePayloadText
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Probe send failed: " + $_.Exception.Message)
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
    if (-not $receiveWorker.IsBusy) {
        $receiveWorker.RunWorkerAsync()
    }
})

$form.Add_FormClosing({
    $probeTimer.Stop()
    if ($receiveWorker.IsBusy) {
        $receiveWorker.CancelAsync()
    }

    Close-UdpClients
})

[void]$form.ShowDialog()

