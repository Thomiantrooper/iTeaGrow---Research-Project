# iTeaGrow Backend - Background Production Server with Auto-Restart
# Run with: powershell -ExecutionPolicy Bypass -File start_background.ps1
# Or to run hidden: powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File start_background.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$env:DEBUG = "False"
$env:HOST = "0.0.0.0"
$env:PORT = "8000"

$logFile = Join-Path $scriptDir "server.log"
$maxRetries = 100
$retryDelay = 5

Write-Host "========================================" -ForegroundColor Green
Write-Host " iTeaGrow Backend - Production Server" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Log file: $logFile"
Write-Host "Server will auto-restart on crash (max $maxRetries retries)"
Write-Host ""

# Install deps
Write-Host "Checking dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt -q 2>&1 | Out-Null

for ($i = 0; $i -lt $maxRetries; $i++) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "[$timestamp] Starting server (attempt $($i + 1))..."
    Write-Host $msg -ForegroundColor Cyan
    Add-Content -Path $logFile -Value $msg

    try {
        $process = Start-Process -FilePath "python" `
            -ArgumentList "-m", "uvicorn", "main:app", "--host", $env:HOST, "--port", $env:PORT, "--workers", "2" `
            -WorkingDirectory $scriptDir `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput "$scriptDir\stdout.log" `
            -RedirectStandardError "$scriptDir\stderr.log"

        $process.WaitForExit()
        $exitCode = $process.ExitCode
    } catch {
        $exitCode = -1
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "[$timestamp] Server exited with code $exitCode. Restarting in $retryDelay seconds..."
    Write-Host $msg -ForegroundColor Yellow
    Add-Content -Path $logFile -Value $msg

    Start-Sleep -Seconds $retryDelay
}

Write-Host "Max retries reached. Exiting." -ForegroundColor Red
