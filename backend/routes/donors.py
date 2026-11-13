from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from db import get_db
from models import Donante, TipoSangre
from db_manager import obtener_resumen_banco_como_string, obtener_donantes_como_string

router = APIRouter(prefix="/donors", tags=["donors"])


# Esquemas de entrada y salida
class DonorCreateRequest(BaseModel):
    nombre: str
    tipo_sangre: str  # Ej: 'O+', 'A-', etc.


class DonorResponse(BaseModel):
    id: int
    nombre_donante: str
    tipo_sangre: str

    class Config:
        from_attributes = True


@router.get("", response_model=List[DonorResponse], summary="Obtener todos los donantes (JSON)")
def list_donors(limit: int = 50, db: Session = Depends(get_db)):
    """
    Retorna la lista de donantes en formato JSON estructurado.
    Ideal para aplicaciones web, Flutter o APIs externas.
    """
    donantes = db.query(Donante).limit(limit).all()
    resultado = []
    for d in donantes:
        tipo = d.tipo_sangre.tipo if d.tipo_sangre else "Desconocido"
        resultado.append(DonorResponse(
            id=d.id,
            nombre_donante=d.nombre_donante,
            tipo_sangre=tipo
        ))
    return resultado


@router.get("/text", response_class=PlainTextResponse, summary="Obtener donantes como STRING plano")
def list_donors_as_string(limit: int = 15):
    """
    Retorna los donantes directamente como una cadena de texto (string).
    Ideal si otro script solo quiere leer texto formateado sin parsear JSON.
    """
    return obtener_donantes_como_string(limite=limit)


@router.get("/summary", response_class=PlainTextResponse, summary="Resumen del banco como STRING")
def get_bank_summary():
    """
    Retorna el resumen de estadísticas de la base de datos como string.
    """
    return obtener_resumen_banco_como_string()


@router.post("", status_code=status.HTTP_201_CREATED, summary="Crear un donante vía API")
def create_donor(data: DonorCreateRequest, db: Session = Depends(get_db)):
    """
    Inserta un donante en Neon DB a partir de un JSON enviado por cualquier cliente.
    """
    tipo = db.query(TipoSangre).filter(TipoSangre.tipo == data.tipo_sangre.upper().strip()).first()
    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de sangre '{data.tipo_sangre}' no válido."
        )

    nuevo_donante = Donante(
        nombre_donante=data.nombre,
        tipo_sangre_id=tipo.id
    )
    db.add(nuevo_donante)
    db.commit()
    db.refresh(nuevo_donante)

    return {
        "mensaje": "Donante creado exitosamente",
        "id": nuevo_donante.id,
        "nombre": nuevo_donante.nombre_donante,
        "tipo_sangre": tipo.tipo
    }
