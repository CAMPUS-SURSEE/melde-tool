# Kleiner lokaler Server zum Anschauen und Testen von site\index.html.
# Aufruf aus diesem Ordner heraus:
#   powershell -ExecutionPolicy Bypass -File serve.ps1
# Danach im Browser http://localhost:8123/ oeffnen. Beenden mit Strg + C.

$datei = Join-Path $PSScriptRoot 'site\index.html'
if (-not (Test-Path $datei)) { throw "Nicht gefunden: $datei" }

$l = New-Object Net.HttpListener
$l.Prefixes.Add('http://localhost:8123/')
$l.Prefixes.Add('http://127.0.0.1:8123/')
$l.Start()
Write-Host "Laeuft auf http://localhost:8123/  (Beenden mit Strg + C)"

while ($true) {
  $ctx = $l.GetContext()
  $bytes = [IO.File]::ReadAllBytes($datei)
  $ctx.Response.ContentType = 'text/html; charset=utf-8'
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}
