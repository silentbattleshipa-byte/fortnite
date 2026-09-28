$root = $PSScriptRoot
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8147)
$listener.Start()
Write-Output "Serving $root on http://127.0.0.1:8147/"
while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $requestLine = $reader.ReadLine()
    while ($null -ne ($line = $reader.ReadLine()) -and $line -ne '') {}
    $path = '/'
    if ($requestLine) { $path = $requestLine.Split(' ')[1] }
    if ($path -eq '/') { $path = '/index.html' }
    $file = Join-Path $root ($path.TrimStart('/') -replace '/', '\')
    $body = [byte[]]@()
    $status = '404 Not Found'
    if (Test-Path -LiteralPath $file -PathType Leaf) {
      $body = [System.IO.File]::ReadAllBytes($file)
      $status = '200 OK'
    }
    $mime = 'text/html; charset=utf-8'
    if ($file -like '*.js') { $mime = 'application/javascript' }
    $header = "HTTP/1.1 $status`r`nContent-Type: $mime`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($hb, 0, $hb.Length)
    $stream.Write($body, 0, $body.Length)
    $stream.Flush()
  } catch {} finally { $client.Close() }
}
