from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from db import get_db
import models

router = APIRouter(prefix="/citas", tags=["Citas"])


@router.get("/", response_model=List[models.CitaResponse])
def listar_citas(db: Session = Depends(get_db)):
    return db.query(models.Cita).order_by(models.Cita.fecha_hora.asc()).all()


@router.get("/{id_cita}", response_model=models.CitaResponse)
def obtener_cita(id_cita: int, db: Session = Depends(get_db)):
    cita = db.query(models.Cita).filter(models.Cita.id_cita == id_cita).first()
    if not cita:
        raise HTTPException(status_code=404, detail="Cita no encontrada")
    return cita


@router.post("/", response_model=models.CitaResponse, status_code=status.HTTP_201_CREATED)
def crear_cita(payload: models.CitaCreate, db: Session = Depends(get_db)):
    donante = db.query(models.Donante).filter(models.Donante.id == payload.id_donante).first()
    if not donante:
        raise HTTPException(status_code=404, detail="Donante no encontrado")

    if payload.id_personal is not None:
        personal = db.query(models.PersonalSalud).filter(
            models.PersonalSalud.id == payload.id_personal
        ).first()
        if not personal:
            raise HTTPException(status_code=404, detail="Personal de salud no encontrado")

    nueva = models.Cita(**payload.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


@router.put("/{id_cita}", response_model=models.CitaResponse)
def editar_cita(id_cita: int, payload: models.CitaUpdate, db: Session = Depends(get_db)):
    cita_db = db.query(models.Cita).filter(models.Cita.id_cita == id_cita).first()
    if not cita_db:
        raise HTTPException(status_code=404, detail="Cita no encontrada")

    datos = payload.model_dump(exclude_unset=True)

    if "id_personal" in datos and datos["id_personal"] is not None:
        personal = db.query(models.PersonalSalud).filter(
            models.PersonalSalud.id == datos["id_personal"]
        ).first()
        if not personal:
            raise HTTPException(status_code=404, detail="Personal de salud no encontrado")

    for campo, valor in datos.items():
        setattr(cita_db, campo, valor)

    db.commit()
    db.refresh(cita_db)
    return cita_db


@router.delete("/{id_cita}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_cita(id_cita: int, db: Session = Depends(get_db)):
    cita_db = db.query(models.Cita).filter(models.Cita.id_cita == id_cita).first()
    if not cita_db:
        raise HTTPException(status_code=404, detail="Cita no encontrada")
    db.delete(cita_db)
    db.commit()
