param (
    [string]$url = "wss://free.blr2.piesocket.com/v3/1?api_key=BT6QPL15GIlioXwdU0TwDMyM2yFUXjef44gROpTg&notify_self=1"
)

Add-Type -AssemblyName System.Net.WebSockets
$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$cts = [System.Threading.CancellationToken]::None

Write-Host "Connecting to $url ..."
$ws.ConnectAsync($url, $cts).Wait()

Write-Host "Connected!"

# Start listener job
Start-Job -ScriptBlock {
    param($ws)

    $buffer = New-Object byte[] 1024

    while ($ws.State -eq "Open") {
        $segment = New-Object System.ArraySegment[byte] -ArgumentList $buffer
        $result = $ws.ReceiveAsync($segment, [Threading.CancellationToken]::None).Result

        if ($result.Count -gt 0) {
            $msg = [Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
            Write-Host "`n[RECEIVED] $msg"
        }
    }
} -ArgumentList $ws | Out-Null

# Sender loop
while ($ws.State -eq "Open") {
    $input = Read-Host "Send"

    if ($input -eq "exit") {
        break
    }

    $bytes = [Text.Encoding]::UTF8.GetBytes($input)
    $segment = New-Object System.ArraySegment[byte] -ArgumentList $bytes

    $ws.SendAsync($segment,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        $cts
    ).Wait()
}

$ws.CloseAsync(
    [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
    "bye",
    $cts
).Wait()

Write-Host "Disconnected"
