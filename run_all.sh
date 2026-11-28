#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FLUTTER_DIR="$ROOT_DIR/flutter_app"
DEVICE="${1:-chrome}"
BACKEND_PORT="${PORT:-8000}"
API_URL="http://127.0.0.1:${BACKEND_PORT}"

if [[ -x "$BACKEND_DIR/venv/Scripts/python.exe" ]]; then
  PYTHON_BIN="$BACKEND_DIR/venv/Scripts/python.exe"
elif [[ -x "$BACKEND_DIR/venv/bin/python" ]]; then
  PYTHON_BIN="$BACKEND_DIR/venv/bin/python"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "Error: No se encontró Python ni el entorno virtual en backend/venv." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: No se encontró 'flutter' en el PATH." >&2
  exit 1
fi

BACKEND_PID=""
cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    echo ""
    echo "Deteniendo backend (PID $BACKEND_PID)..."
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "Iniciando backend FastAPI en $API_URL..."
(
  cd "$BACKEND_DIR"
  exec "$PYTHON_BIN" -m uvicorn main:app --reload --host 0.0.0.0 --port "$BACKEND_PORT"
) &
BACKEND_PID=$!

echo "Esperando a que el backend responda en $API_URL/health..."
READY=0
for _ in $(seq 1 30); do
  if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
    echo "Error: El backend se detuvo inesperadamente." >&2
    exit 1
  fi

  if "$PYTHON_BIN" -c "import urllib.request; urllib.request.urlopen('${API_URL}/health', timeout=1)" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 0.5
done

if [[ "$READY" -ne 1 ]]; then
  echo "Aviso: El backend tardó más de lo esperado en responder; iniciando Flutter de todas formas..."
else
  echo "Backend listo en $API_URL (Swagger: $API_URL/docs)"
fi

echo "Iniciando Flutter en dispositivo '$DEVICE'..."
cd "$FLUTTER_DIR"
flutter run -d "$DEVICE" --dart-define="API_BASE_URL=$API_URL"
