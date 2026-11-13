from datetime import datetime, date, timezone
from pydantic import BaseModel, ConfigDict
from sqlalchemy import Column, Integer, String, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from db import Base


class TipoSangre(Base):
    __tablename__ = "tipo_sangre"

    id = Column(Integer, primary_key=True, index=True)
    tipo = Column(String(3), nullable=False, unique=True)  # Ej. 'A+', 'O-'

    donantes = relationship("Donante", back_populates="tipo_sangre")

    def __repr__(self) -> str:
        return f"<TipoSangre {self.tipo}>"


class Ubicacion(Base):
    __tablename__ = "ubicacion"

    id = Column(Integer, primary_key=True, index=True)
    nombre_ubicacion = Column(String(100), nullable=False)


class CargoPersonal(Base):
    __tablename__ = "cargo_personal"

    id = Column(Integer, primary_key=True, index=True)
    nombre_cargo = Column(String(100), nullable=False, unique=True)
    descripcion = Column(String(250), nullable=False)


class PersonalSalud(Base):
    __tablename__ = "personal_salud"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    id_cargo = Column(Integer, ForeignKey("cargo_personal.id"), nullable=False)
    correo = Column(String(100), unique=True)

    cargo = relationship("CargoPersonal")


class Donante(Base):
    __tablename__ = "donante"

    id = Column(Integer, primary_key=True, index=True)
    nombre_donante = Column(String(100), nullable=False)
    tipo_sangre_id = Column(Integer, ForeignKey("tipo_sangre.id"), nullable=True)

    tipo_sangre = relationship("TipoSangre", back_populates="donantes")

    def to_string(self) -> str:
        tipo = self.tipo_sangre.tipo if self.tipo_sangre else "Desconocido"
        return f"Donante #{self.id}: {self.nombre_donante} (Tipo de sangre: {tipo})"

    def __repr__(self) -> str:
        return f"<Donante id={self.id} nombre='{self.nombre_donante}'>"


class Extraccion(Base):
    __tablename__ = "extraccion"

    id = Column(Integer, primary_key=True, index=True)
    id_donante = Column(Integer, ForeignKey("donante.id"), nullable=False)
    id_personal = Column(Integer, ForeignKey("personal_salud.id"), nullable=False)
    fecha_extraccion = Column(Date, default=date.today, nullable=False)
    vigencia_dias = Column(Integer, default=35, nullable=False)
    # Columna calculada en la BD PostgreSQL (GENERATED ALWAYS AS)
    fecha_vencimiento = Column(Date)

    donante = relationship("Donante")
    personal = relationship("PersonalSalud")


class PeticionSangre(Base):
    __tablename__ = "peticion_sangre"

    id = Column(Integer, primary_key=True, index=True)
    id_donante = Column(Integer, ForeignKey("donante.id"), nullable=False)
    id_tipo = Column(Integer, ForeignKey("tipo_sangre.id"), nullable=False)
    cantidad_ml = Column(Float, nullable=False)
    prioridad = Column(String(50), nullable=False)
    fecha_solicitud = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    tipo_sangre = relationship("TipoSangre")
    donante = relationship("Donante")

    def to_string(self) -> str:
        tipo = self.tipo_sangre.tipo if self.tipo_sangre else f"Tipo #{self.id_tipo}"
        nombre = self.donante.nombre_donante if self.donante else f"Donante #{self.id_donante}"
        return f"Petición #{self.id}: {self.cantidad_ml}ml [{tipo}] | Prioridad: {self.prioridad} | Donante: {nombre}"


class FileRecord(Base):
    __tablename__ = "files"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    filename = Column(String(255), nullable=False)
    file_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    stored_path = Column(String(500), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


# --- Pydantic Schemas ---

class FileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    filename: str
    file_type: str
    file_size: int
    created_at: datetime


class UploadResponse(BaseModel):
    message: str
    file: FileResponse
