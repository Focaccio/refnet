param(
    [string]$LocalIP = '0.0.0.0',
    [int]$LocalPort = 7000,
    [string]$RemoteIP = '127.0.0.1',
    [int]$RemotePort = 7001
)

$scriptPath = Join-Path $PSScriptRoot 'udp-chat.ps1'
& $scriptPath -Side A -DisplayName 'Side A' -LocalIP $LocalIP -LocalPort $LocalPort -RemoteIP $RemoteIP -RemotePort $RemotePort
