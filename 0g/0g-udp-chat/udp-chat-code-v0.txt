param(
    [ValidateSet('A','Z')]
    [string]$Side = 'A',

    [string]$LocalIP = '0.0.0.0',
    [int]$LocalPort = 7000,

    [Parameter(Mandatory = $true)]
    [string]$RemoteIP,

    [Parameter(Mandatory = $true)]
    [int]$RemotePort,

    [string]$DisplayName = ''
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    $DisplayName = "Side $Side"
}

$fontMain = New-Object System.Drawing.Font('Segoe UI', 10)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 9)

$form = New-Object System.Windows.Forms.Form
$form.Text = "UDP P2P Chat - $DisplayName"
$form.Size = New-Object System.Drawing.Size(860, 600)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(760, 500)
$form.KeyPreview = $true

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(14, 12)
$lblTitle.Size = New-Object System.Drawing.Size(820, 24)
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
$lblTitle.Text = "Peer-to-Peer UDP Chat ($DisplayName)"
$form.Controls.Add($lblTitle)

$lblLocal = New-Object System.Windows.Forms.Label
$lblLocal.Location = New-Object System.Drawing.Point(14, 42)
$lblLocal.Size = New-Object System.Drawing.Size(820, 20)
$lblLocal.Font = $fontSmall
$lblLocal.Text = "Local Endpoint: $LocalIP`:$LocalPort"
$form.Controls.Add($lblLocal)

$lblRemote = New-Object System.Windows.Forms.Label
$lblRemote.Location = New-Object System.Drawing.Point(14, 62)
$lblRemote.Size = New-Object System.Drawing.Size(820, 20)
$lblRemote.Font = $fontSmall
$lblRemote.Text = "Remote Endpoint: $RemoteIP`:$RemotePort"
$form.Controls.Add($lblRemote)

$txtHistory = New-Object System.Windows.Forms.TextBox
$txtHistory.Location = New-Object System.Drawing.Point(14, 90)
$txtHistory.Size = New-Object System.Drawing.Size(820, 390)
$txtHistory.Multiline = $true
$txtHistory.ScrollBars = 'Vertical'
$txtHistory.ReadOnly = $true
$txtHistory.Font = $fontMain
$txtHistory.BackColor = [System.Drawing.Color]::White
$txtHistory.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($txtHistory)

$txtMessage = New-Object System.Windows.Forms.TextBox
$txtMessage.Location = New-Object System.Drawing.Point(14, 494)
$txtMessage.Size = New-Object System.Drawing.Size(700, 30)
$txtMessage.Font = $fontMain
$txtMessage.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($txtMessage)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Location = New-Object System.Drawing.Point(724, 492)
$btnSend.Size = New-Object System.Drawing.Size(110, 34)
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

$localAddress = [System.Net.IPAddress]::Parse($LocalIP)
$localEndpoint = New-Object System.Net.IPEndPoint($localAddress, $LocalPort)

$udp = New-Object System.Net.Sockets.UdpClient
$udp.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
$udp.ExclusiveAddressUse = $false
$udp.Client.Bind($localEndpoint)

$remoteAddress = [System.Net.IPAddress]::Parse($RemoteIP)
$remoteEndpoint = New-Object System.Net.IPEndPoint($remoteAddress, $RemotePort)

$statusLabel.Text = "Listening on $LocalIP`:$LocalPort | Sending to $RemoteIP`:$RemotePort"
Add-ChatLine -Prefix '[System]' -Message "Initialized as $DisplayName."

$receiveWorker = New-Object System.ComponentModel.BackgroundWorker
$receiveWorker.WorkerSupportsCancellation = $true

$receiveWorker.add_DoWork({
    param($sender, $e)

    $anyEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

    while (-not $sender.CancellationPending) {
        try {
            if ($udp.Available -gt 0) {
                $bytes = $udp.Receive([ref]$anyEndpoint)
                $msg = [System.Text.Encoding]::UTF8.GetString($bytes)
                $peer = $anyEndpoint.ToString()

                $form.BeginInvoke([Action]{
                    Add-ChatLine -Prefix "[$peer]" -Message $msg
                }) | Out-Null
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
        [void]$udp.Send($payload, $payload.Length, $remoteEndpoint)
        Add-ChatLine -Prefix "[$DisplayName]" -Message $text
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

    try {
        $udp.Close()
    } catch {}
})

[void]$form.ShowDialog()
