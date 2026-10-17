$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $workspaceRoot 'docker-compose.debug.yml'

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    $dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path -LiteralPath $dockerDesktop)) {
        throw 'Docker is not running and Docker Desktop was not found.'
    }

    Write-Host 'Starting Docker Desktop...'
    Start-Process -FilePath $dockerDesktop -WindowStyle Hidden

    $dockerReady = $false
    foreach ($attempt in 1..120) {
        Start-Sleep -Seconds 1
        docker info *> $null
        if ($LASTEXITCODE -eq 0) {
            $dockerReady = $true
            break
        }
    }

    if (-not $dockerReady) {
        throw 'Docker Desktop did not become ready within 120 seconds.'
    }
}

Write-Host 'Starting nopCommerce debug infrastructure...'
docker compose -f $composeFile up -d --wait --wait-timeout 120
if ($LASTEXITCODE -ne 0) {
    throw 'The nopCommerce debug infrastructure did not become healthy.'
}
