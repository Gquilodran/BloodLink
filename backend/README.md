# BloodLink - Backend API (FastAPI)

Backend en Python utilizando FastAPI y SQLAlchemy como puente seguro hacia la base de datos y sistema de almacenamiento de archivos.

## Características

- **FastAPI** con documentación Swagger interactiva (`/docs`) y ReDoc (`/redoc`).
- **Arquitectura desacoplada**: el cliente (Flutter) nunca interactúa con la base de datos de manera directa.
- **Configuración mediante variables de entorno** (`pydantic-settings`).
- **Soporte multibase de datos**: SQLite por defecto (cero configuración); compatible con PostgreSQL, MySQL, etc., solo cambiando `DATABASE_URL`.
- **Subida segura de archivos**: validación configurable de extensiones y tamaño máximo.

---

## Requisitos Previos

- Python 3.10 o superior.

---

## Instalación y Puesta en Marcha

### 1. Crear y activar entorno virtual

**En Windows (PowerShell):**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**En Linux / macOS:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Configurar variables de entorno

Copia la plantilla de ejemplo:
```bash
cp .env.example .env
```
Edita `.env` para ajustar parámetros como `MAX_FILE_SIZE_MB`, `ALLOWED_EXTENSIONS`, o la conexión a tu base de datos si utilizas PostgreSQL/MySQL.

### 4. Iniciar el servidor

```bash
uvicorn main:app --reload
```

El servidor estará disponible en:
- API Base: `http://localhost:8000`
- Documentación Swagger: `http://localhost:8000/docs`
- Verificación de estado: `http://localhost:8000/health`

---

## Endpoints Principales

- `POST /files/upload`: Subir archivo multipart (`file`). Retorna el `id` y metadatos del archivo registrado.
- `GET /files/{id}`: Consulta metadatos del archivo registrado por ID.
- `GET /files/{id}/download`: Descarga el archivo físico del servidor.
- `GET /health`: Estado del servicio.

---

## Cambio de Base de Datos

Para cambiar de base de datos no es necesario modificar la lógica de la aplicación:
1. En `.env`, modifica la variable `DATABASE_URL`:
   - **PostgreSQL**: `postgresql://usuario:contraseña@localhost:5432/nombre_bd` (requiere `pip install psycopg2-binary`)
   - **MySQL**: `mysql+pymysql://usuario:contraseña@localhost:3306/nombre_bd` (requiere `pip install pymysql`)
2. `db.py` y los modelos de SQLAlchemy se adaptarán automáticamente.
