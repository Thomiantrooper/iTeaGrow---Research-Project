#!/usr/bin/env pwsh

# Wait for server to be ready
Start-Sleep -Seconds 2

# Test 1: Check /docs endpoint
Write-Host "Testing /docs endpoint..." -ForegroundColor Cyan
$docsResponse = Invoke-WebRequest -Uri "http://127.0.0.1:8000/docs" -ErrorAction SilentlyContinue
if ($docsResponse.StatusCode -eq 200 -and $docsResponse.Content -match "swagger") {
    Write-Host "✓ /docs endpoint works (HTTP 200)" -ForegroundColor Green
} else {
    Write-Host "✗ /docs endpoint failed (HTTP $($docsResponse.StatusCode))" -ForegroundColor Red
}

# Test 2: Check /health endpoint
Write-Host "`nTesting /health endpoint..." -ForegroundColor Cyan
$healthResponse = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -ErrorAction SilentlyContinue
if ($healthResponse.StatusCode -eq 200) {
    Write-Host "✓ /health endpoint works (HTTP 200)" -ForegroundColor Green
    $health = $healthResponse.Content | ConvertFrom-Json
    Write-Host "  Status: $($health.status)" -ForegroundColor Yellow
    Write-Host "  Services:" -ForegroundColor Yellow
    $health.services | Get-Member -MemberType NoteProperty | ForEach-Object {
        $value = $health.services.($_.Name)
        $color = if ($value -eq "healthy") { "Green" } else { "Yellow" }
        Write-Host "    - $($_.Name): $value" -ForegroundColor $color
    }
} else {
    Write-Host "✗ /health endpoint failed (HTTP $($healthResponse.StatusCode))" -ForegroundColor Red
}

# Test 3: Check /health/live endpoint
Write-Host "`nTesting /health/live endpoint..." -ForegroundColor Cyan
$liveResponse = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health/live" -ErrorAction SilentlyContinue
if ($liveResponse.StatusCode -eq 200) {
    Write-Host "✓ /health/live endpoint works (HTTP 200)" -ForegroundColor Green
} else {
    Write-Host "✗ /health/live endpoint failed (HTTP $($liveResponse.StatusCode))" -ForegroundColor Red
}

Write-Host "`nAll tests completed!" -ForegroundColor Cyan
