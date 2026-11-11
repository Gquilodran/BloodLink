import os
import uuid
import shutil
from pathlib import Path
from fastapi import UploadFile
from sqlalchemy.orm import Session

from config import settings
from models import FileRecord

"""
Storage service responsible for saving and reading files.

HOW TO CHANGE THE STORAGE BACKEND:
- Currently stores files on the local filesystem in `settings.UPLOAD_DIR`.
- To switch to cloud storage (AWS S3, Google Cloud Storage, Azure Blob, MinIO),
  replace the file write and read logic in `save_file` and `get_file_path` with
  the appropriate SDK calls (e.g., boto3, google-cloud-storage).
"""


class StorageService:
    def __init__(self, upload_dir: str = settings.UPLOAD_DIR):
        self.upload_dir = Path(upload_dir)
        # Ensure the uploads directory exists
        self.upload_dir.mkdir(parents=True, exist_ok=True)

    def validate_file(self, upload_file: UploadFile) -> None:
        """
        Validates the uploaded file against allowed extensions.
        Size validation is performed during read to handle streaming uploads safely.
        """
        filename = upload_file.filename or ""
        ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""

        if not ext or ext not in settings.allowed_extensions_set:
            allowed = ", ".join(sorted(settings.allowed_extensions_set))
            raise ValueError(f"Extensión no permitida (.{ext}). Extensiones permitidas: {allowed}")

    def save_file(self, db: Session, upload_file: UploadFile) -> FileRecord:
        """
        Validates, saves the uploaded file to disk and registers metadata in the database.
        
        Raises ValueError if validation fails (e.g. invalid type or file too large).
        """
        self.validate_file(upload_file)

        original_filename = upload_file.filename or "unknown"
        ext = original_filename.rsplit(".", 1)[-1].lower() if "." in original_filename else ""

        # Generate a unique stored filename to prevent collisions and path traversal
        unique_stored_name = f"{uuid.uuid4().hex}.{ext}" if ext else uuid.uuid4().hex
        destination_path = self.upload_dir / unique_stored_name

        total_bytes = 0
        chunk_size = 1024 * 1024  # 1MB chunks

        try:
            with open(destination_path, "wb") as buffer:
                while True:
                    chunk = upload_file.file.read(chunk_size)
                    if not chunk:
                        break
                    total_bytes += len(chunk)

                    if total_bytes > settings.max_file_size_bytes:
                        # Clean up partial file on size limit violation
                        buffer.close()
                        if destination_path.exists():
                            destination_path.unlink()
                        raise ValueError(
                            f"El archivo excede el tamaño máximo permitido de {settings.MAX_FILE_SIZE_MB} MB"
                        )
                    buffer.write(chunk)
        finally:
            upload_file.file.close()

        # TODO: Implement virus scanning or deep MIME-type verification here
        # TODO: If using S3 or GCS, upload `destination_path` and store the object URI

        content_type = upload_file.content_type or f"application/{ext}"

        file_record = FileRecord(
            filename=original_filename,
            file_type=content_type,
            file_size=total_bytes,
            stored_path=str(destination_path),
        )

        db.add(file_record)
        db.commit()
        db.refresh(file_record)

        return file_record

    def get_file_by_id(self, db: Session, file_id: int) -> FileRecord | None:
        """Retrieves file metadata from the database by ID."""
        return db.query(FileRecord).filter(FileRecord.id == file_id).first()

    def get_file_path(self, file_record: FileRecord) -> Path:
        """Returns the physical Path of the stored file."""
        return Path(file_record.stored_path)


storage_service = StorageService()
