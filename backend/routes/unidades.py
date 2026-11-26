from datetime import date, datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field

from solicitudd import (
    editar_unidad_sangre,
    eliminar_unidad_sangre,
    obtener_todas_las_ubicaciones,
    obtener_todas_las_unidades_sangre,
    obtener_unidad_sangre_por_id,
    registrar_unidad_sangre,
)

router = APIRouter(tags=["unidades"])


class UnidadCreateRequest(BaseModel):
    nombre_donante: str = Field(..., min_length=1, max_length=100)
    tipo_sangre: str = Field(..., min_length=2, max_length=3)
    nombre_ubicacion: str = Field(..., min_length=1, max_length=100)
    fecha_hora_extraccion: Optional[datetime] = None
    fecha_caducidad: Optional[date] = None
    dias_vigencia: int = Field(default=42, ge=1, le=365)


class UnidadUpdateRequest(BaseModel):
    tipo_sangre: Optional[str] = Field(default=None, min_length=2, max_length=3)
    nombre_donante: Optional[str] = Field(default=None, min_length=1, max_length=100)
    nombre_ubicacion: Optional[str] = Field(default=None, min_length=1, max_length=100)
    fecha_hora_extraccion: Optional[datetime] = None
    fecha_caducidad: Optional[date] = None


@router.get("/unidades", summary="Listar unidades de sangre")
def listar_unidades(tipo_sangre: Optional[str] = Query(default=None)):
    """Retorna todas las unidades de sangre registradas, opcionalmente filtradas por tipo."""
    unidades = obtener_todas_las_unidades_sangre()
    if tipo_sangre and tipo_sangre.strip().lower() != "todos":
        tipo_filtro = tipo_sangre.strip().upper()
        unidades = [
            u for u in unidades
            if (u.get("nombre_tipo_sangre") or "").upper() == tipo_filtro
        ]
    return unidades


@router.get("/unidades/{unidad_id}", summary="Obtener una unidad de sangre por ID")
def detalle_unidad(unidad_id: int):
    unidad = obtener_unidad_sangre_por_id(unidad_id)
    if not unidad:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No existe la unidad con ID {unidad_id}.",
        )
    return unidad


@router.post("/unidades", status_code=status.HTTP_201_CREATED, summary="Registrar nueva unidad de sangre")
def crear_unidad(payload: UnidadCreateRequest):
    fecha_ext = payload.fecha_hora_extraccion or datetime.now()
    if payload.fecha_caducidad and payload.fecha_caducidad < fecha_ext.date():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La fecha de caducidad no puede ser anterior a la fecha de extracción.",
        )

    try:
        creada = registrar_unidad_sangre(
            nombre_donante=payload.nombre_donante,
            tipo_sangre=payload.tipo_sangre,
            nombre_ubicacion=payload.nombre_ubicacion,
            fecha_extraccion=fecha_ext,
            dias_vigencia=payload.dias_vigencia,
            fecha_caducidad=payload.fecha_caducidad,
            crear_ubicacion_si_no_existe=True,
        )
        return obtener_unidad_sangre_por_id(creada["id"]) or creada
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al registrar la unidad de sangre: {e}",
        )


@router.put("/unidades/{unidad_id}", summary="Editar una unidad de sangre")
def actualizar_unidad(unidad_id: int, payload: UnidadUpdateRequest):
    try:
        editar_unidad_sangre(
            unidad_id=unidad_id,
            tipo_sangre=payload.tipo_sangre.upper().strip() if payload.tipo_sangre else None,
            nombre_donante=payload.nombre_donante.strip() if payload.nombre_donante else None,
            nombre_ubicacion=payload.nombre_ubicacion.strip() if payload.nombre_ubicacion else None,
            fecha_extraccion=payload.fecha_hora_extraccion,
            fecha_caducidad=payload.fecha_caducidad,
            crear_si_no_existe=True,
        )
        return obtener_unidad_sangre_por_id(unidad_id)
    except ValueError as e:
        mensaje = str(e)
        code = status.HTTP_404_NOT_FOUND if "No existe la unidad" in mensaje else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=mensaje)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar la unidad: {e}",
        )


@router.delete("/unidades/{unidad_id}", summary="Retirar una unidad de sangre del inventario")
def retirar_unidad(unidad_id: int):
    try:
        eliminada = eliminar_unidad_sangre(unidad_id)
        return {"mensaje": "Unidad retirada del inventario.", "unidad": eliminada}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al retirar la unidad: {e}",
        )


@router.get("/ubicaciones", summary="Listar ubicaciones disponibles")
def listar_ubicaciones():
    return obtener_todas_las_ubicaciones()
