$line = Get-Content pubspec.yaml | Select-String '^version:' | Select-Object -First 1
if (-not $line) {
    Write-Error "Не найдена строка 'version:' в pubspec.yaml"
    exit 1
}

$full = ($line.Line -split ':')[1].Trim()
$userVersion = if ($full -match '\+') { ($full -split '\+')[0] } else { $full }

flutter build web --dart-define=APP_VERSION=$userVersion
