# Parameter block for startup defaults and role identity.
# Inputs come from command-line args; values seed UI fields and initial network state.
# Outputs are script-level defaults used by initialization and validation blocks.
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

# Runtime constants define strict error behavior, UI limits, and probe signatures.
# Inputs are static literals; outputs are byte payloads and limits reused by send/receive logic.
# This keeps protocol behavior consistent across both sides.
$ErrorActionPreference = 'Stop'
$maxInputLines = 3
$probePayloadText = 'ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ'
$remoteProbePayloadText = 'AAAAA-AAAAA-AAAAA-AAAAA-AAAAA'
$probePayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($probePayloadText)

$fontMain = New-Object System.Drawing.Font('Segoe UI', 12)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 10)
$fontTitle = New-Object System.Drawing.Font('Segoe UI Semibold', 13)

# Main form and control construction block for operator interaction.
# Inputs are default values and layout settings; outputs are bound controls used by all handlers.
# Network, send, and receive blocks depend on these controls for state and display.
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

# Status/timer primitives provide live connection state and periodic probe scheduling.
# Inputs are interval and status text defaults; outputs are timers consumed by lifecycle events.
# These tie UI responsiveness to networking cadence.
$status = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Spring = $true
$statusLabel.TextAlign = 'MiddleLeft'
$statusLabel.Text = 'Starting...'
[void]$status.Items.Add($statusLabel)
$form.Controls.Add($status)

$probeTimer = New-Object System.Windows.Forms.Timer
$probeTimer.Interval = 30000

# Chat rendering helper normalizes timestamped output into the history textbox.
# Inputs are a prefix and message from system/send/receive paths; output is one appended UI line.
# Centralizing this keeps visual formatting consistent across all event sources.
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

# Input guard enforces the max line count while preventing recursive text-change events.
# Input is current textbox content; output is a trimmed message buffer safe for transmit.
# This protects send behavior and keeps UI constraints predictable.
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

# Mutable network/session state lives in script scope for cross-handler access.
# Inputs come from defaults or Apply updates; outputs feed bind/send/receive decisions.
# This is the shared contract between config, transport, and UI label blocks.
$script:currentSideAIP = $SideAIP
$script:currentSideZIP = $SideZIP
$script:currentAToZSourcePort = $SideAToSideZSourcePort
$script:currentAToZDestPort = $SideAToSideZDestPort
$script:currentZToASourcePort = $SideZToSideASourcePort
$script:currentZToADestPort = $SideZToSideADestPort
$script:sendEndpoint = $null
$script:sendUdp = $null
$script:recvUdp = $null

# Label updater projects current transport settings into human-readable channel text.
# Inputs are current script state values; outputs are status/label strings in the UI.
# It links runtime socket config to operator-visible diagnostics.
function Update-NetworkLabels {
    $lblChannel1.Text = "Channel Z -> A : side-z $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> side-a $($script:currentSideAIP)`:$($script:currentZToADestPort)"
    $lblChannel2.Text = "Channel A -> Z : side-a $($script:currentSideAIP)`:$($script:currentAToZSourcePort) -> side-z $($script:currentSideZIP)`:$($script:currentAToZDestPort)"
    $statusLabel.Text = "Send(Z->A): $($script:currentSideZIP)`:$($script:currentZToASourcePort) -> $($script:currentSideAIP)`:$($script:currentZToADestPort) | Recv(A->Z): $($script:currentSideZIP)`:$($script:currentAToZDestPort)"
}

# Socket cleanup block closes and nulls active UDP clients safely.
# Inputs are current socket references; output is a reset transport state.
# It is used before rebinds and during shutdown to avoid port/resource leaks.
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

# Network initialization binds send/receive sockets and computes remote endpoint.
# Inputs are validated IP/port values; outputs are live UDP clients and endpoint targets.
# This block connects UI configuration to operational packet flow.
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

# Port parser validates numeric input and enforces UDP port range constraints.
# Inputs are textbox strings; output is a sanitized int or a thrown validation error.
# This prevents invalid configuration from reaching socket bind logic.
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

# Peer filter checks whether a received packet endpoint matches expected sender identity.
# Inputs are packet endpoint plus expected IP/port; output is a boolean trust decision.
# Receive rendering uses this to tag lines as verified or unverified.
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

# Apply handler reads UI fields, validates them, and reinitializes the network stack.
# Inputs are operator-entered IP/port values; outputs are refreshed sockets and status lines.
# This is the runtime bridge from user changes to active transport behavior.
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

# Startup bootstrap activates default network settings at launch.
# Inputs are parameter defaults; outputs are first socket bindings and a startup chat note.
# This ensures the app can send/receive immediately after form shown.
Initialize-Network -NextSideAIP $SideAIP -NextSideZIP $SideZIP -NextAToZSourcePort $SideAToSideZSourcePort -NextAToZDestPort $SideAToSideZDestPort -NextZToASourcePort $SideZToSideASourcePort -NextZToADestPort $SideZToSideADestPort
Add-ChatLine -Prefix '[System]' -Message "Initialized as $DisplayName."

# Receive poll loop drains available datagrams and renders them in chat history.
# Inputs are socket bytes and endpoint metadata; outputs are Probe RX/chat lines with trust tags.
# It is the core ingress path linking UDP packets to visible conversation state.
$receiveTimer = New-Object System.Windows.Forms.Timer
$receiveTimer.Interval = 70
$receiveTimer.Add_Tick({
    try {
        if ($null -eq $script:recvUdp) {
            return
        }

        while ($script:recvUdp.Available -gt 0) {
            $rxEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            $bytes = $script:recvUdp.Receive([ref]$rxEndpoint)
            $msg = [System.Text.Encoding]::UTF8.GetString($bytes)
            $endpointText = $rxEndpoint.ToString()

            $isExpectedPeer = Test-ExpectedPeer -Endpoint $rxEndpoint -ExpectedPort $script:currentAToZSourcePort -ExpectedIP $script:currentSideAIP
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
    } catch {
        Add-ChatLine -Prefix '[Error]' -Message ("Receive failed: " + $_.Exception.Message)
    }
})

# Send handler transmits operator text to the remote endpoint.
# Inputs are message textbox content plus active send socket; output is UDP payload + local echo line.
# This is the primary egress path for human chat messages.
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

# Probe sender emits periodic heartbeat payloads for path visibility.
# Inputs are probe bytes and current endpoint; outputs are UDP probe packets and Probe TX lines.
# Receive logic on the peer side classifies matching payloads as Probe RX.
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

# UI event wiring connects controls and timers to functional handlers.
# Inputs are user clicks/keys and timer ticks; outputs are send/apply/probe actions.
# This composes independent logic blocks into one interactive workflow.
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

# Form shown lifecycle starts active timers once UI is ready.
# Inputs are initialized controls/sockets; outputs are live receive polling and probe cadence.
# This marks the transition from setup phase to runtime operation.
$form.Add_Shown({
    $txtMessage.Focus()
    $probeTimer.Start()
    $receiveTimer.Start()
})

# Form closing lifecycle stops timers and releases sockets cleanly.
# Inputs are active runtime resources; output is a deterministic shutdown state.
# This prevents lingering bindings and makes restart/apply cycles reliable.
$form.Add_FormClosing({
    $probeTimer.Stop()
    $receiveTimer.Stop()

    Close-UdpClients
})

# Entry point transfers control to the WinForms message loop.
# Input is fully wired UI/network state; output is ongoing event-driven execution.
# All previous blocks prepare dependencies for this run phase.
[void]$form.ShowDialog()


