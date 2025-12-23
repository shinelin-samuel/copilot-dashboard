import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Build the SQLAlchemy database URL from the environment. Use psycopg driver for PostgreSQL.
# Expected format: postgresql+psycopg://user:password@host:port/dbname
DEFAULT_PG_URL = os.getenv("DEFAULT_DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/copilot")
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_PG_URL)

# Create engine for PostgreSQL (or whatever is provided in DATABASE_URL)
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
