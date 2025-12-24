# python
import logging
import uvicorn
from copilotkit import CopilotKitRemoteEndpoint, LangGraphAgent
from copilotkit.integrations.fastapi import add_fastapi_endpoint
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .agent.graph import graph
from .api import insights
from .db.database import Base, engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="InsightCopilot API", description="API for extracting insights from the Sakila database", version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

sdk = CopilotKitRemoteEndpoint(
    agents=[
        LangGraphAgent(
            name="insight_copilot_agent",
            description="A copilot agent that can extract insights from the Sakila database",
            graph=graph,
        )
    ],
)

# If agent may perform blocking work, consider setting use_thread_pool=True
add_fastapi_endpoint(app, sdk, "/copilotkit", use_thread_pool=False)

app.include_router(insights.router, prefix="/api/v1", tags=["insights"])


@app.get("/")
async def root():
    return {
        "message": "Welcome to InsightCopilot API",
        "version": "1.0.0",
        "docs_url": "/docs",
    }


if __name__ == "__main__":
    # Increase keep-alive to avoid socket termination during long streaming requests
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        timeout_keep_alive=120,
        log_level="info",
        proxy_headers=True,
    )