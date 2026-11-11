from datetime import datetime, timezone
from pydantic import BaseModel, ConfigDict
from sqlalchemy import Column, Integer, String, DateTime
from db import Base


class FileRecord(Base):
    """
    SQLAlchemy table model representing an uploaded file.
    
    Fields:
    - id: Unique integer identifier
    - filename: Original name of the uploaded file
    - file_type: Content-Type MIME type or extension
    - file_size: Size in bytes
    - stored_path: Path on disk (or storage key) where file is stored
    - created_at: Timestamp of upload
    """
    __tablename__ = "files"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    filename = Column(String(255), nullable=False)
    file_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    stored_path = Column(String(500), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # TODO: Relate file to an authenticated user when auth is implemented:
    # user_id = Column(Integer, ForeignKey("users.id"), nullable=True)


# --- Pydantic Schemas for API Serialization ---

class FileResponse(BaseModel):
    """Schema representing file metadata in API responses."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    filename: str
    file_type: str
    file_size: int
    created_at: datetime


class UploadResponse(BaseModel):
    """Schema returned after a successful file upload."""
    message: str
    file: FileResponse
