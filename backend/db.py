from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from config import settings

"""
Database connection and session management module.

HOW TO CHANGE THE DATABASE:
1. Update DATABASE_URL in your .env file:
   - PostgreSQL: postgresql://user:password@localhost:5432/dbname
   - MySQL:      mysql+pymysql://user:password@localhost:3306/dbname
   - SQLite:     sqlite:///./bloodlink.db (default)
2. Install the required driver in requirements.txt (e.g., psycopg2-binary or pymysql).
3. No code changes are required here; SQLAlchemy handles the dialect differences.
"""

# SQLite requires check_same_thread=False for multi-threaded FastAPI execution.
connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    echo=settings.DEBUG,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency that yields a database session per request
    and ensures it is properly closed when the request finishes.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """
    Creates database tables defined in SQLAlchemy models if they do not exist.
    Called on application startup.
    """
    Base.metadata.create_all(bind=engine)
