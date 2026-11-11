import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application configuration settings loaded from environment variables
    or a .env file.
    
    IMPORTANT: Never hardcode secrets here. Use the .env file (excluded in .gitignore).
    """
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # Application settings
    APP_NAME: str = "BloodLink API"
    APP_ENV: str = "development"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # CORS settings (comma-separated list of origins, or * for all)
    ALLOWED_ORIGINS: str = "*"

    # Database configuration
    # Default to SQLite for zero-config local development.
    # To use PostgreSQL, MySQL, etc., change this in your .env file:
    # e.g.: postgresql://user:password@localhost:5432/bloodlink
    DATABASE_URL: str = "sqlite:///./bloodlink.db"
    DB_USER: str = ""
    DB_PASSWORD: str = ""
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "bloodlink_db"

    # File storage configuration
    MAX_FILE_SIZE_MB: int = 10
    ALLOWED_EXTENSIONS: str = "pdf,png,jpg,jpeg,doc,docx,txt"
    UPLOAD_DIR: str = "uploads"

    # TODO: Add JWT / Auth configuration when implementing authentication
    # SECRET_KEY: str = ""
    # ALGORITHM: str = "HS256"
    # ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    @property
    def cors_origins(self) -> List[str]:
        """Parse ALLOWED_ORIGINS into a list of strings."""
        if self.ALLOWED_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]

    @property
    def max_file_size_bytes(self) -> int:
        """Convert MAX_FILE_SIZE_MB to bytes."""
        return self.MAX_FILE_SIZE_MB * 1024 * 1024

    @property
    def allowed_extensions_set(self) -> set[str]:
        """Return lowercase set of allowed file extensions."""
        return {ext.strip().lower().lstrip(".") for ext in self.ALLOWED_EXTENSIONS.split(",") if ext.strip()}


settings = Settings()
