param(
    [string]$Device = "chrome",
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $RootDir "backend"
$FlutterDir = Join-Path $RootDir "flutter_app"
$ApiUrl = "http://127.0.0.1:$Port"

$VenvPython = Join-Path $BackendDir "venv\Scripts\python.exe"
if (Test-Path $VenvPython) {
    $PythonBin = $VenvPython
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonBin = "python"
} else {
    Write-Error "No se encontró Python ni el entorno virtual en backend\venv."
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "No se encontró 'flutter' en el PATH."
    exit 1
}

Write-Host "Iniciando backend FastAPI en $ApiUrl..." -ForegroundColor Cyan
$BackendProcess = Start-Process `
    -FilePath $PythonBin `
    -ArgumentList "-m", "uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "$Port" `
    -WorkingDirectory $BackendDir `
    -PassThru

try {
    Write-Host "Esperando a que el backend responda en $ApiUrl/health..." -ForegroundColor Yellow
    $Ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        if ($BackendProcess.HasExited) {
            throw "El backend se cerró inesperadamente con código $($BackendProcess.ExitCode)."
        }
        try {
            $resp = Invoke-WebRequest -Uri "$ApiUrl/health" -TimeoutSec 1 -UseBasicParsing
            if ($resp.StatusCode -eq 200) {
                $Ready = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    if ($Ready) {
        Write-Host "Backend listo en $ApiUrl (Swagger: $ApiUrl/docs)" -ForegroundColor Green
    } else {
        Write-Warning "El backend tardó más de lo esperado en responder; iniciando Flutter..."
    }

    Write-Host "Iniciando Flutter en dispositivo '$Device'..." -ForegroundColor Cyan
    Push-Location $FlutterDir
    try {
        flutter run -d $Device --dart-define="API_BASE_URL=$ApiUrl"
    } finally {
        Pop-Location
    }
} finally {
    if ($BackendProcess -and -not $BackendProcess.HasExited) {
        Write-Host "`nDeteniendo backend (PID $($BackendProcess.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
