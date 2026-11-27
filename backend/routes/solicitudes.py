from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field

from solicitudd import (
    actualizar_estado_peticion,
    crear_peticion_sangre,
    marcar_peticion_cancelada,
    marcar_peticion_completa,
    obtener_peticion_por_id,
    obtener_todas_las_peticiones,
    editar_peticion_sangre,
    eliminar_peticion_sangre
)

router = APIRouter(prefix="/solicitudes", tags=["solicitudes"])


class SolicitudCreateRequest(BaseModel):
    tipo_sangre: str = Field(..., min_length=2, max_length=3)
    cantidad_ml: float = Field(..., gt=0)
    prioridad: str = Field(..., min_length=1, max_length=50)
    centro_salud: str = Field(..., min_length=1, max_length=200)
    fecha_solicitud: Optional[datetime] = None


class SolicitudEstadoRequest(BaseModel):
    estado: str = Field(..., min_length=1, max_length=30)


@router.get("", summary="Listar solicitudes de sangre")
def listar_solicitudes(estado: Optional[str] = Query(default=None)):
    """Retorna todas las solicitudes de sangre, opcionalmente filtradas por estado."""
    solicitudes = obtener_todas_las_peticiones()
    if estado and estado.strip().lower() not in ("todos", "todas"):
        estado_filtro = estado.strip().lower()
        solicitudes = [
            s for s in solicitudes
            if (s.get("estado") or "").lower() == estado_filtro
        ]
    return solicitudes


@router.get("/{solicitud_id}", summary="Obtener una solicitud de sangre por ID")
def detalle_solicitud(solicitud_id: int):
    solicitud = obtener_peticion_por_id(solicitud_id)
    if not solicitud:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No existe la petición con ID {solicitud_id}.",
        )
    return solicitud


@router.post("", status_code=status.HTTP_201_CREATED, summary="Crear nueva solicitud de sangre")
def crear_solicitud(payload: SolicitudCreateRequest):
    try:
        creada = crear_peticion_sangre(
            tipo_sangre=payload.tipo_sangre.strip().upper(),
            cantidad_ml=payload.cantidad_ml,
            prioridad=payload.prioridad.strip(),
            centro_salud=payload.centro_salud.strip(),
            fecha_solicitud=payload.fecha_solicitud or datetime.now(),
        )
        return obtener_peticion_por_id(creada["id"]) or creada
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear la solicitud: {e}",
        )


@router.patch("/{solicitud_id}/completar", summary="Marcar solicitud como completada")
def completar_solicitud(solicitud_id: int):
    try:
        marcar_peticion_completa(solicitud_id)
        return obtener_peticion_por_id(solicitud_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al completar la solicitud: {e}",
        )


@router.patch("/{solicitud_id}/cancelar", summary="Marcar solicitud como cancelada")
def cancelar_solicitud(solicitud_id: int):
    try:
        marcar_peticion_cancelada(solicitud_id)
        return obtener_peticion_por_id(solicitud_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al cancelar la solicitud: {e}",
        )


@router.patch("/{solicitud_id}/estado", summary="Actualizar estado de una solicitud")
def cambiar_estado_solicitud(solicitud_id: int, payload: SolicitudEstadoRequest):
    estado = payload.estado.strip().lower()
    try:
        if estado == "completada":
            marcar_peticion_completa(solicitud_id)
        elif estado == "cancelada":
            marcar_peticion_cancelada(solicitud_id)
        else:
            actualizar_estado_peticion(solicitud_id, estado)
        return obtener_peticion_por_id(solicitud_id)
    except ValueError as e:
        mensaje = str(e)
        code = status.HTTP_404_NOT_FOUND if "no existe" in mensaje.lower() else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=mensaje)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar el estado: {e}",
        )


class SolicitudUpdateRequest(BaseModel):
    tipo_sangre: Optional[str] = Field(default=None, min_length=2, max_length=3)
    cantidad_ml: Optional[float] = Field(default=None, gt=0)
    prioridad: Optional[str] = Field(default=None, min_length=1, max_length=50)
    centro_salud: Optional[str] = Field(default=None, min_length=1, max_length=200)
    estado: Optional[str] = Field(default=None, min_length=1, max_length=30)


@router.put("/{solicitud_id}", summary="Editar una solicitud de sangre")
def editar_solicitud(solicitud_id: int, payload: SolicitudUpdateRequest):
    try:
        editar_peticion_sangre(
            id_peticion=solicitud_id,
            tipo_sangre=payload.tipo_sangre,
            cantidad_ml=payload.cantidad_ml,
            prioridad=payload.prioridad,
            centro_salud=payload.centro_salud,
            estado=payload.estado,
        )
        return obtener_peticion_por_id(solicitud_id)
    except ValueError as e:
        mensaje = str(e)
        code = status.HTTP_404_NOT_FOUND if "no existe" in mensaje.lower() else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=mensaje)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al editar la solicitud: {e}",
        )
@router.delete("/{solicitud_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Eliminar una solicitud de sangre")
def eliminar_solicitud(solicitud_id: int):
    try:
        eliminar_peticion_sangre(solicitud_id)
        return None
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar la solicitud: {e}",
        )