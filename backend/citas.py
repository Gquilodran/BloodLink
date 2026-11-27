from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import models, schemas
from ..db import get_db

router = APIRouter(prefix="/citas", tags=["Citas"])

@router.post("/", response_model=schemas.CitaResponse)
def crear_cita(cita: schemas.CitaCreate, db: Session = Depends(get_db)):
    # Lógica similar a la creación en unidades.py o solicitudes.py
    nueva_cita = models.Cita(**cita.model_dump())
    db.add(nueva_cita)
    db.commit()
    db.refresh(nueva_cita)
    return nueva_cita

@router.put("/{id_cita}", response_model=schemas.CitaResponse)
def editar_cita(id_cita: int, cita: schemas.CitaUpdate, db: Session = Depends(get_db)):
    cita_db = db.query(models.Cita).filter(models.Cita.id_cita == id_cita).first()
    if not cita_db:
        raise HTTPException(status_code=404, detail="Cita no encontrada")
    
    for field, value in cita.model_dump(exclude_unset=True).items():
        setattr(cita_db, field, value)
    
    db.commit()
    db.refresh(cita_db)
    return cita_db{peticion_verificada['prioridad']}")
