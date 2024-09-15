# UDP Chat Server

# Prompt for server IP and port
$serverIP = Read-Host "Enter the server IP address (or press Enter for any available IP)"
if ([string]::IsNullOrEmpty($serverIP)) {
    $serverIP = "0.0.0.0"
}
$port = Read-Host "Enter the UDP port number"

# Create UDP server
$udpServer = New-Object System.Net.Sockets.UdpClient $port

Write-Host "Server listening on $serverIP`:$port"
Write-Host "Waiting for client messages..."

$remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

while ($true) {
    # Receive message
    $receivedBytes = $udpServer.Receive([ref]$remoteEndPoint)
    $receivedMessage = [Text.Encoding]::ASCII.GetString($receivedBytes)

    Write-Host "Client ($($remoteEndPoint.Address):$($remoteEndPoint.Port)): $receivedMessage"

    # Send response
    $response = Read-Host "Server"
    $responseBytes = [Text.Encoding]::ASCII.GetBytes($response)
    $udpServer.Send($responseBytes, $responseBytes.Length, $remoteEndPoint)
}

# Note: This server will run indefinitely. Press Ctrl+C to stop it.