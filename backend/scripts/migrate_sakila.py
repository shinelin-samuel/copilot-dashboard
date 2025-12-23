#!/usr/bin/env python3
"""Migrate the bundled Sakila SQLite DB into PostgreSQL (improved).

Usage:
  # Ensure a postgres instance is running and DATABASE_URL env var points to it (defaults to local docker-compose service)
  export DATABASE_URL=postgresql+psycopg://postgres:postgres@postgres:5432/copilot
  python backend/scripts/migrate_sakila.py

This improved script:
- Disables foreign-key checks during insert (session_replication_role = 'replica')
- Coerces DataFrame columns to types compatible with Postgres target table's column types
- Uses chunked/multi inserts to improve performance

Note: This is a pragmatic one-time migration tool. For production-grade migrations use pgloader or a clean SQL dump.
"""

import os
import sys
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# Ensure backend directory is on sys.path so we can import app package
SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from sqlalchemy import create_engine, inspect, text
import pandas as pd

# Import models to access metadata
try:
    from app.db.models import Base  # noqa: E402
except Exception as e:
    logger.error("Unable to import models from app.db.models: %s", e)
    raise

# Paths and URLs
SQLITE_FILE = os.getenv("SQLITE_FILE", str(BACKEND_DIR / "data" / "sqlite-sakila.db"))
SQLITE_URL = f"sqlite:///{SQLITE_FILE}"
POSTGRES_URL = os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/copilot")

logger.info("SQLite source: %s", SQLITE_URL)
logger.info("Postgres target: %s", POSTGRES_URL)

# Create engines
sqlite_engine = create_engine(SQLITE_URL)
pg_engine = create_engine(POSTGRES_URL)

# Create tables in Postgres using SQLAlchemy models (if not exists)
logger.info("Creating tables in Postgres from SQLAlchemy metadata...")
Base.metadata.create_all(bind=pg_engine)
logger.info("Tables created or verified.")

# Inspect sqlite tables
sqlite_inspector = inspect(sqlite_engine)
pg_inspector = inspect(pg_engine)

tables = sqlite_inspector.get_table_names()
logger.info("Found %d tables in sqlite: %s", len(tables), tables)

# Helper to coerce dtypes based on Postgres column types
def coerce_df_to_pg_table(df: pd.DataFrame, table_name: str):
    try:
        cols = pg_inspector.get_columns(table_name)
    except Exception:
        # If the table isn't present in pg metadata, return df unchanged
        return df

    for col in cols:
        name = col['name']
        if name not in df.columns:
            continue
        pgtype = str(col['type']).lower()
        # Nulls -> keep as pd.NA
        if df[name].isnull().all():
            df[name] = pd.NA
            continue
        # Integers
        if ('int' in pgtype) or ('smallint' in pgtype) or ('bigint' in pgtype):
            df[name] = pd.to_numeric(df[name], errors='coerce').astype('Int64')
        # Numeric/decimal/float
        elif ('numeric' in pgtype) or ('decimal' in pgtype) or ('double' in pgtype) or ('real' in pgtype) or ('float' in pgtype):
            df[name] = pd.to_numeric(df[name], errors='coerce')
        # Boolean
        elif 'bool' in pgtype:
            # Map common sqlite boolean representations
            df[name] = df[name].map({1: True, 0: False, '1': True, '0': False, 't': True, 'f': False, 'true': True, 'false': False}).where(pd.notnull(df[name]))
            df[name] = df[name].astype('boolean')
        # Datetime or timestamp
        elif ('timestamp' in pgtype) or ('date' in pgtype) or ('time' in pgtype):
            df[name] = pd.to_datetime(df[name], errors='coerce')
        else:
            # Leave as-is (strings, text)
            df[name] = df[name].astype(object)
    return df

# Perform migration with FK checks disabled
with pg_engine.connect() as conn:
    logger.info("Disabling foreign key checks in Postgres session...")
    conn.execute(text("SET session_replication_role = 'replica';"))
    conn.commit()

    for table in tables:
        logger.info("Migrating table: %s", table)
        try:
            # Read table from sqlite
            try:
                df = pd.read_sql_table(table_name=table, con=sqlite_engine)
            except Exception:
                df = pd.read_sql_query(f"SELECT * FROM \"{table}\"", con=sqlite_engine)
        except Exception as e:
            logger.exception("Failed to read table %s from sqlite: %s", table, e)
            continue

        if df.empty:
            logger.info("Table %s is empty; skipping insert.", table)
            continue

        # Coerce dataframe to match Postgres target types
        df = coerce_df_to_pg_table(df, table)

        # Write to Postgres in chunks
        try:
            df.to_sql(name=table, con=pg_engine, if_exists="append", index=False, method='multi', chunksize=500)
            logger.info("Inserted %d rows into %s", len(df), table)
        except Exception as e:
            logger.exception("Failed to insert rows into %s: %s", table, e)

    logger.info("Re-enabling foreign key checks in Postgres session...")
    conn.execute(text("SET session_replication_role = 'origin';"))
    conn.commit()

logger.info("Migration completed.")

