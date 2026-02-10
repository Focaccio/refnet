param(
    [string]$LocalIP = '0.0.0.0',
    [int]$LocalPort = 7001,
    [string]$RemoteIP = '127.0.0.1',
    [int]$RemotePort = 7000
)

$scriptPath = Join-Path $PSScriptRoot 'udp-chat.ps1'
& $scriptPath -Side Z -DisplayName 'Side Z' -LocalIP $LocalIP -LocalPort $LocalPort -RemoteIP $RemoteIP -RemotePort $RemotePort
