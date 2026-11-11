from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import FileResponse as FastAPIFileResponse
from sqlalchemy.orm import Session

from db import get_db
from models import FileResponse, UploadResponse
from services.storage import storage_service

router = APIRouter(prefix="/files", tags=["files"])


@router.post(
    "/upload",
    response_model=UploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Subir un archivo",
    description="Recibe un archivo multipart, valida tipo y tamaño, lo guarda y registra sus metadatos."
)
async def upload_file(
    file: UploadFile = File(..., description="Archivo a subir"),
    db: Session = Depends(get_db)
):
    """
    Endpoint para subir archivos desde la app móvil u otros clientes.
    """
    # TODO: Validar autenticación de usuario (ej. Depends(get_current_user))
    # TODO: Registrar el ID del usuario propietario del archivo

    try:
        saved_record = storage_service.save_file(db=db, upload_file=file)
    except ValueError as e:
        # Errores de validación de tamaño o extensión
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        # TODO: Agregar logger estructurado para auditar errores
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al procesar el archivo."
        )

    return UploadResponse(
        message="Archivo subido exitosamente",
        file=FileResponse.model_validate(saved_record)
    )


@router.get(
    "/{file_id}",
    response_model=FileResponse,
    summary="Obtener metadatos de un archivo",
    description="Devuelve la información del archivo registrado según su ID."
)
def get_file_metadata(
    file_id: int,
    db: Session = Depends(get_db)
):
    # TODO: Validar permisos de lectura del usuario sobre este archivo

    record = storage_service.get_file_by_id(db=db, file_id=file_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Archivo con id {file_id} no encontrado."
        )
    return FileResponse.model_validate(record)


@router.get(
    "/{file_id}/download",
    summary="Descargar archivo físico",
    description="Descarga el archivo físico almacenado en el servidor."
)
def download_file(
    file_id: int,
    db: Session = Depends(get_db)
):
    # TODO: Validar token de descarga o permisos de acceso

    record = storage_service.get_file_by_id(db=db, file_id=file_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Archivo con id {file_id} no encontrado."
        )

    file_path = storage_service.get_file_path(record)
    if not file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="El archivo ya no se encuentra disponible en el almacenamiento."
        )

    return FastAPIFileResponse(
        path=file_path,
        media_type=record.file_type,
        filename=record.filename
    )
