# Tea Leaf Disease Detection - Unified Run Script
# Starts Backend, Frontend, MongoDB, and Ollama

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$SkipMongo,
    [switch]$SkipOllama,
    [switch]$Help
)

$ErrorActionPreference = "Continue"

# Colors for output
function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

function Show-Help {
    Write-Color "Tea Leaf Disease Detection - Unified Run Script" "Cyan"
    Write-Host ""
    Write-Host "Usage: .\run.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -BackendOnly    Start only the backend server"
    Write-Host "  -FrontendOnly   Start only the Flutter frontend"
    Write-Host "  -SkipMongo      Skip MongoDB startup check"
    Write-Host "  -SkipOllama     Skip Ollama startup check"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run.ps1                    # Start everything"
    Write-Host "  .\run.ps1 -BackendOnly       # Start only backend"
    Write-Host "  .\run.ps1 -FrontendOnly      # Start only Flutter app"
    exit 0
}

if ($Help) { Show-Help }

Write-Color "`n========================================" "Cyan"
Write-Color "  Tea Leaf Disease Detection Platform" "Cyan"
Write-Color "========================================`n" "Cyan"

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check if MongoDB is running
function Start-MongoDB {
    if ($SkipMongo) {
        Write-Color "[SKIP] MongoDB check skipped" "Yellow"
        return
    }

    Write-Host "[CHECK] Checking MongoDB status..."

    try {
        $mongoProcess = Get-Process mongod -ErrorAction SilentlyContinue
        if ($mongoProcess) {
            Write-Color "[OK] MongoDB is already running (PID: $($mongoProcess.Id))" "Green"
        } else {
            Write-Color "[INFO] MongoDB not running. Attempting to start..." "Yellow"

            # Try to start MongoDB
            $mongoPath = "C:\Program Files\MongoDB\Server\7.0\bin\mongod.exe"
            if (-not (Test-Path $mongoPath)) {
                $mongoPath = "C:\Program Files\MongoDB\Server\6.0\bin\mongod.exe"
            }
            if (-not (Test-Path $mongoPath)) {
                $mongoPath = "mongod"  # Try PATH
            }

            # Start MongoDB in background
            Start-Process -FilePath $mongoPath -ArgumentList "--dbpath", "C:\data\db" -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            $mongoProcess = Get-Process mongod -ErrorAction SilentlyContinue
            if ($mongoProcess) {
                Write-Color "[OK] MongoDB started successfully" "Green"
            } else {
                Write-Color "[WARN] Could not start MongoDB. Please start it manually." "Yellow"
                Write-Host "       Run: mongod --dbpath C:\data\db"
            }
        }
    } catch {
        Write-Color "[WARN] MongoDB check failed: $_" "Yellow"
    }
}

# Check if Ollama is running
function Start-Ollama {
    if ($SkipOllama) {
        Write-Color "[SKIP] Ollama check skipped" "Yellow"
        return
    }

    Write-Host "[CHECK] Checking Ollama status..."

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Color "[OK] Ollama is running" "Green"
        }
    } catch {
        Write-Color "[INFO] Ollama not responding. Attempting to start..." "Yellow"

        try {
            Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Write-Color "[OK] Ollama started" "Green"
        } catch {
            Write-Color "[WARN] Could not start Ollama. Please start it manually." "Yellow"
            Write-Host "       Run: ollama serve"
        }
    }
}

# Start Backend
function Start-Backend {
    Write-Host "`n[START] Starting Backend Server (with MongoDB)..."

    # Activate virtual environment if exists
    $venvPath = Join-Path $scriptDir "disease_env\Scripts\Activate.ps1"
    $backendDir = Join-Path $scriptDir "backend"

    if (Test-Path $venvPath) {
        Write-Host "[INFO] Activating virtual environment..."
    }

    # Start uvicorn from backend directory
    $backendCmd = "python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
    Write-Color "[INFO] Running: $backendCmd" "Gray"

    if ($FrontendOnly) {
        return
    }

    # Start in new window from backend directory
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendDir'; & '$venvPath'; $backendCmd"

    Write-Color "[OK] Backend started at http://localhost:8000" "Green"
    Write-Host "     API Docs: http://localhost:8000/docs"
}

# Start Frontend
function Start-Frontend {
    Write-Host "`n[START] Starting Flutter Frontend..."

    $flutterDir = Join-Path $scriptDir "frontend\iTeaGrow---Research-Project"

    if (-not (Test-Path $flutterDir)) {
        Write-Color "[WARN] Flutter project not found at: $flutterDir" "Yellow"
        return
    }

    if ($BackendOnly) {
        return
    }

    # Start Flutter (try Windows first, fallback to Edge)
    Write-Host "[INFO] Starting Flutter (Windows desktop or Edge fallback)..."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$flutterDir'; flutter run -d windows; if (`$LASTEXITCODE -ne 0) { flutter run -d edge }"

    Write-Color "[OK] Flutter frontend starting..." "Green"
}

# Main execution
Write-Host "[INFO] Project Directory: $scriptDir`n"

if (-not $FrontendOnly) {
    Start-MongoDB
    Start-Ollama
    Start-Backend
}

if (-not $BackendOnly) {
    Start-Frontend
}

Write-Color "`n========================================" "Cyan"
Write-Color "  All Services Started!" "Green"
Write-Color "========================================" "Cyan"
Write-Host ""
Write-Host "Services:"
Write-Host "  - Backend API:  http://localhost:8000"
Write-Host "  - API Docs:     http://localhost:8000/docs"
Write-Host "  - MongoDB:      mongodb://localhost:27017"
Write-Host "  - Ollama:       http://localhost:11434"
Write-Host ""
Write-Color "Press Ctrl+C in each window to stop services" "Yellow"
