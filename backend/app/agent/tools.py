import json
import os
from typing import Any, Callable, Dict, List

import pandas as pd
from copilotkit.langgraph import copilotkit_emit_state
from langchain_core.runnables.config import RunnableConfig
from langchain_core.tools import tool
from langchain_core.tools.base import InjectedToolCallId
from langgraph.prebuilt import InjectedState
from tenacity import retry, stop_after_attempt, wait_exponential
from typing_extensions import Annotated
from app.logger import get_logger
from sqlalchemy import create_engine, text

logger = get_logger(__name__)

# Database URL (fallback kept for local development)
DEFAULT_PG_URL = os.getenv("DEFAULT_DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/copilot")
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_PG_URL)

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URL)


class SQLDatabase:
    def __init__(self, engine):
        self.engine = engine

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
    def execute_query(self, query: str) -> pd.DataFrame:
        """Execute a SQL query with retry logic."""
        logger.info("Entering execute_query")
        try:
            with self.engine.connect() as conn:
                return pd.read_sql_query(sql=text(query), con=conn)
        except Exception as e:
            raise Exception(f"Database error: {str(e)}")

    def get_schema(self) -> Dict[str, List[str]]:
        """Get the database schema for PostgreSQL."""
        logger.info("Entering get_schema")
        schema = {}
        tables_query = """
            SELECT table_schema, table_name
            FROM information_schema.tables
            WHERE table_type = 'BASE TABLE' AND table_schema NOT IN ('pg_catalog', 'information_schema');
        """
        with self.engine.connect() as conn:
            result = conn.execute(text(tables_query))
            for row in result:
                schema_name, table_name = row
                cols_q = text(
                    "SELECT column_name FROM information_schema.columns WHERE table_schema = :schema AND table_name = :table ORDER BY ordinal_position"
                )
                cols_res = conn.execute(cols_q, {"schema": schema_name, "table": table_name})
                columns = [c[0] for c in cols_res]
                full_table_name = f"{schema_name}.{table_name}"
                schema[full_table_name] = columns
        return schema


# Initialize database
db = SQLDatabase(engine)


@tool(description="Get the database schema", return_direct=False)
async def get_schema(
    tool_call_id: Annotated[str, InjectedToolCallId],
    state: Annotated[Any, InjectedState],
) -> str:
    """Get the database schema."""
    logger.info("Entering @tool.get_schema")
    schema = db.get_schema()
    return json.dumps(schema, indent=2)


@tool(description="Run a query on the database", return_direct=True)
async def run_query(
    tool_call_id: Annotated[str, InjectedToolCallId],
    state: Annotated[Any, InjectedState],
    config: RunnableConfig,
    query: str,
) -> str:
    """Run a SQL query on the database with retry logic."""
    logger.info("Entering @tool.run_query")
    await copilotkit_emit_state(config, {"progress": "Running query..."})
    try:
        result = db.execute_query(query)
        return result.to_json(orient="records")
    except Exception as e:
        return f"Error executing query: {str(e)}"


TOOLS: List[Callable[..., Any]] = [get_schema, run_query]
