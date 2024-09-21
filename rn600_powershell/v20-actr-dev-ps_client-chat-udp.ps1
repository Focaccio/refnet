# UDP Chat Client

# Prompt for server IP and port
$serverIP = Read-Host "Enter the server IP address"
$port = Read-Host "Enter the UDP port number"

# Create UDP client
$udpClient = New-Object System.Net.Sockets.UdpClient

# Connect to the server
$udpClient.Connect($serverIP, $port)

Write-Host "Connected to server at $serverIP`:$port"
Write-Host "Type your messages and press Enter to send. Type 'exit' to quit."

$lineNumber = 1

while ($true) {
    # Get user input
    $message = Read-Host "You"
    
    if ($message -eq "exit") {
        break
    }

    # Add timestamp and line number to the message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] #$lineNumber $message"

    # Send message
    $bytes = [Text.Encoding]::ASCII.GetBytes($formattedMessage)
    $udpClient.Send($bytes, $bytes.Length)

    # Display sent message with timestamp and line number
    Write-Host "Sent: $formattedMessage"

    # Receive response
    $remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    $receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
    $receivedMessage = [Text.Encoding]::ASCII.GetString($receivedBytes)

    # Display received message with timestamp
    $receiveTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Server [$receiveTimestamp]: $receivedMessage"

    $lineNumber++
}

# Close the UDP client
$udpClient.Close()
Write-Host "Disconnected from server."