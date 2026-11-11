# BloodLink

Esqueleto funcional y modular de **BloodLink**, compuesto por:
1. **`backend/`**: API REST en Python (FastAPI + SQLAlchemy) que actúa como puente seguro con la base de datos y gestiona el almacenamiento de archivos.
2. **`flutter_app/`**: Aplicación móvil y multiplataforma en Flutter que permite seleccionar y subir archivos consumiendo la API.

---

## 🔒 Arquitectura y Seguridad

- **La aplicación Flutter NUNCA contiene credenciales ni acceso directo a la base de datos.** Únicamente conoce la URL base del backend expuesta mediante `--dart-define`.
- **El backend en Python es el único componente que interactúa con la base de datos y custodia los secretos**, leyendo toda la configuración de variables de entorno mediante `pydantic-settings`.
- **Repositorio público seguro**: el archivo `.gitignore` previene la subida accidental de archivos `.env`, entornos virtuales `venv/`, archivos de base de datos (`.db`), ejecutables compilados y certificados/llaves.

---

## 📁 Estructura del Proyecto

```text
BloodLink/
├── flutter_app/                    # Aplicación Flutter
│   ├── lib/
│   │   ├── config/
│   │   │   └── app_config.dart     # URL base de la API (vía --dart-define)
│   │   ├── services/
│   │   │   └── upload_service.dart # Servicio multipart y selector de archivos
│   │   ├── screens/
│   │   │   └── upload_screen.dart  # Pantalla con botón de subida y SnackBar
│   │   └── main.dart               # Punto de entrada de la app
│   └── pubspec.yaml
├── backend/                        # API FastAPI
│   ├── config.py                   # Lectura de variables de entorno (pydantic-settings)
│   ├── db.py                       # Conexión SQLAlchemy y gestión de sesiones
│   ├── models.py                   # Modelo de tabla 'files' y esquemas Pydantic
│   ├── main.py                     # Instancia FastAPI, CORS y registro de rutas
│   ├── routes/
│   │   └── files.py                # Endpoints POST /files/upload y GET /files/{id}
│   ├── services/
│   │   └── storage.py              # Validación y persistencia de archivos en disco/BD
│   ├── requirements.txt            # Dependencias Python
│   ├── .env.example                # Plantilla de variables de entorno
│   └── README.md                   # Documentación específica del backend
├── .gitignore                      # Reglas de exclusión para Git (Flutter, Python, .env)
└── README.md                       # Esta guía general
```

---

## 🚀 Guía de Inicio Rápido

### Parte 1: Iniciar el Backend (Python)

1. **Navegar a la carpeta del backend:**
   ```bash
   cd backend
   ```

2. **Crear y activar un entorno virtual:**
   - En Windows (PowerShell):
     ```powershell
     python -m venv venv
     .\venv\Scripts\Activate.ps1
     ```
   - En Linux / macOS:
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. **Instalar dependencias:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configurar el archivo `.env`:**
   ```bash
   # Copiar la plantilla
   cp .env.example .env
   ```
   *Nota: Por defecto viene configurado con SQLite (`bloodlink.db`), por lo que arrancará de inmediato sin requerir configuración adicional.*

5. **Iniciar el servidor en modo desarrollo:**
   ```bash
   uvicorn main:app --reload
   ```
   - El servidor responderá en `http://localhost:8000`.
   - Puedes abrir la documentación interactiva en `http://localhost:8000/docs`.

---

### Parte 2: Iniciar la Aplicación Móvil (Flutter)

1. **Navegar a la carpeta de Flutter:**
   ```bash
   cd flutter_app
   ```

2. **Obtener las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la app:**

   Puedes definir la URL del backend según la plataforma donde pruebes la aplicación:

   - **Emulador Android:**
     ```bash
     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
     ```
     *(La IP `10.0.2.2` es el alias que usa el emulador de Android para comunicarse con el `localhost` de tu máquina).*

   - **Dispositivo físico Android / iOS (misma red WiFi):**
     ```bash
     flutter run --dart-define=API_BASE_URL=http://<IP_LOCAL_DE_TU_PC>:8000
     ```

   - **Navegador Web / Windows Desktop:**
     ```bash
     flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
     # o para Windows:
     flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
     ```

---

## 🗄️ Cambio de Base de Datos

El backend utiliza **SQLAlchemy**, lo que permite cambiar el motor de base de datos sin modificar la lógica de la aplicación:

1. Modifica la variable `DATABASE_URL` en tu archivo `backend/.env`:
   - **PostgreSQL:** `postgresql://usuario:password@localhost:5432/nombre_bd` (instalar `psycopg2-binary`)
   - **MySQL:** `mysql+pymysql://usuario:password@localhost:3306/nombre_bd` (instalar `pymysql`)
   - **SQLite:** `sqlite:///./bloodlink.db` (incluido por defecto)
2. Reinicia `uvicorn` y las tablas se generarán automáticamente.
