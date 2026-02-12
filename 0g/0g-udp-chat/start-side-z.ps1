param(
    [string]$LocalIP = '0.0.0.0',
    [string]$RemoteIP = '127.0.0.1',

    [int]$AtoZSourcePort = 7000,
    [int]$AtoZDestPort = 7000,
    [int]$ZtoASourcePort = 7001,
    [int]$ZtoADestPort = 7001,

    [string]$DisplayName = 'Side Z'
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

$lblChannel1 = New-Object System.Windows.Forms.Label
$lblChannel1.Location = New-Object System.Drawing.Point(14, 42)
$lblChannel1.Size = New-Object System.Drawing.Size(820, 20)
$lblChannel1.Font = $fontSmall
$lblChannel1.Text = "Channel Z -> A : local $LocalIP`:$ZtoASourcePort -> remote $RemoteIP`:$ZtoADestPort"
$form.Controls.Add($lblChannel1)

$lblChannel2 = New-Object System.Windows.Forms.Label
$lblChannel2.Location = New-Object System.Drawing.Point(14, 62)
$lblChannel2.Size = New-Object System.Drawing.Size(820, 20)
$lblChannel2.Font = $fontSmall
$lblChannel2.Text = "Channel A -> Z : remote $RemoteIP`:$AtoZSourcePort -> local $LocalIP`:$AtoZDestPort"
$form.Controls.Add($lblChannel2)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Location = New-Object System.Drawing.Point(14, 82)
$lblHint.Size = New-Object System.Drawing.Size(820, 18)
$lblHint.Font = $fontSmall
$lblHint.Text = "Enter sends. Shift+Enter inserts newline. Message input is limited to 3 lines."
$form.Controls.Add($lblHint)

$txtHistory = New-Object System.Windows.Forms.TextBox
$txtHistory.Location = New-Object System.Drawing.Point(14, 106)
$txtHistory.Size = New-Object System.Drawing.Size(820, 350)
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

$localAddress = [System.Net.IPAddress]::Parse($LocalIP)
$remoteAddress = [System.Net.IPAddress]::Parse($RemoteIP)

$sendEndpoint = New-Object System.Net.IPEndPoint($remoteAddress, $ZtoADestPort)

$sendUdp = New-Object System.Net.Sockets.UdpClient
$sendUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
$sendUdp.ExclusiveAddressUse = $false
$sendUdp.Client.Bind((New-Object System.Net.IPEndPoint($localAddress, $ZtoASourcePort)))

$recvUdp = New-Object System.Net.Sockets.UdpClient
$recvUdp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
$recvUdp.ExclusiveAddressUse = $false
$recvUdp.Client.Bind((New-Object System.Net.IPEndPoint($localAddress, $AtoZDestPort)))

$statusLabel.Text = "Send(Z->A): $LocalIP`:$ZtoASourcePort -> $RemoteIP`:$ZtoADestPort | Recv(A->Z): $LocalIP`:$AtoZDestPort"
Add-ChatLine -Prefix '[System]' -Message "Initialized as $DisplayName."

$receiveWorker = New-Object System.ComponentModel.BackgroundWorker
$receiveWorker.WorkerSupportsCancellation = $true

$receiveWorker.add_DoWork({
    param($sender, $e)

    $anyEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

    while (-not $sender.CancellationPending) {
        try {
            if ($recvUdp.Available -gt 0) {
                $bytes = $recvUdp.Receive([ref]$anyEndpoint)
                $msg = [System.Text.Encoding]::UTF8.GetString($bytes)

                if (($anyEndpoint.Port -eq $AtoZSourcePort) -and ($anyEndpoint.Address.Equals($remoteAddress))) {
                    $form.BeginInvoke([Action]{
                        Add-ChatLine -Prefix "[$($anyEndpoint.ToString()) A->Z]" -Message $msg
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
        $payload = [System.Text.Encoding]::UTF8.GetBytes($text)
        [void]$sendUdp.Send($payload, $payload.Length, $sendEndpoint)
        Add-ChatLine -Prefix "[$DisplayName Z->A]" -Message $text
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
    $txtMessage.Focus()
    if (-not $receiveWorker.IsBusy) {
        $receiveWorker.RunWorkerAsync()
    }
})

$form.Add_FormClosing({
    if ($receiveWorker.IsBusy) {
        $receiveWorker.CancelAsync()
    }

    try { $sendUdp.Close() } catch {}
    try { $recvUdp.Close() } catch {}
})

[void]$form.ShowDialog()
