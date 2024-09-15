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

while ($true) {
    # Get user input
    $message = Read-Host "You"
    
    if ($message -eq "exit") {
        break
    }

    # Send message
    $bytes = [Text.Encoding]::ASCII.GetBytes($message)
    $udpClient.Send($bytes, $bytes.Length)

    # Receive response
    $remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    $receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
    $receivedMessage = [Text.Encoding]::ASCII.GetString($receivedBytes)

    Write-Host "Server: $receivedMessage"
}

# Close the connection
$udpClient.Close()