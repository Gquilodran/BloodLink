import sys
from pathlib import Path
from contextlib import asynccontextmanager

# Ensure backend directory is in python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from config import settings
from db import init_db
from routes.files import router as files_router
from routes.donors import router as donors_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan events.
    Executes table creation and initial setup on startup.
    """
    # Initialize database tables
    init_db()
    # TODO: Connect to Redis / message queue if implemented in the future
    yield
    # TODO: Cleanup resources, close pools on shutdown if needed


app = FastAPI(
    title=settings.APP_NAME,
    description="Backend puente para BloodLink con almacenamiento de archivos y base de datos.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configuración de CORS (permite conectar la app de Flutter en desarrollo y producción)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registrar rutas
app.include_router(files_router)
app.include_router(donors_router)

# TODO: Registrar futuros routers:
# app.include_router(auth_router)
# app.include_router(users_router)


@app.get("/", tags=["health"])
def root():
    return {
        "app": settings.APP_NAME,
        "status": "online",
        "docs": "/docs"
    }


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok", "env": settings.APP_ENV}


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
