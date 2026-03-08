"""
FastAPI application for Intelligent Pipeline System.
Provides REST API endpoints for pipeline infrastructure data with PostGIS/GeoJSON support.
"""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import routers and database
from routers import pipelines
from database import engine, Base


# ============================================================================
# Lifespan Event Handler
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manage application lifecycle: startup and shutdown events.
    Optionally create tables on startup if using SQLAlchemy.
    """
    # Startup
    logger.info("Starting Intelligent Pipeline System API")
    # Tables are assumed to already exist (created via SQL schema)
    # Uncomment below to auto-create tables from ORM:
    # async with engine.begin() as conn:
    #     await conn.run_sync(Base.metadata.create_all)
    
    yield
    
    # Shutdown
    logger.info("Shutting down API")
    await engine.dispose()


# ============================================================================
# FastAPI Application
# ============================================================================

app = FastAPI(
    title="Intelligent Pipeline System API",
    description="FastAPI backend for pipeline infrastructure management with PostGIS GIS support",
    version="1.0.0",
    lifespan=lifespan,
)


# ============================================================================
# CORS Configuration
# ============================================================================

origins = [
    "http://localhost:3000",      # React dev server
    "http://localhost:5173",      # Vite dev server
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
    "*",  # Allow all origins for development (restrict in production)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# Health Check Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    """Simple health check endpoint."""
    return {"status": "healthy", "service": "pipeline-api"}


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Intelligent Pipeline System API",
        "version": "1.0.0",
        "description": "REST API for pipeline infrastructure GIS data",
        "docs": "/docs",
        "openapi_schema": "/openapi.json",
        "endpoints": {
            "pipelines": "/api/pipelines",
            "route_detail": "/api/pipelines/{route_id}",
            "route_segments": "/api/pipelines/{route_id}/segments",
            "route_stations": "/api/pipelines/{route_id}/stations",
            "route_valves": "/api/pipelines/{route_id}/valves",
            "route_devices": "/api/pipelines/{route_id}/devices",
        }
    }


# ============================================================================
# Include Routers
# ============================================================================

app.include_router(pipelines.router)


# ============================================================================
# Error Handlers
# ============================================================================

@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    """Handle ValueError exceptions."""
    return {
        "detail": f"Validation error: {str(exc)}",
        "status_code": 400,
    }


if __name__ == "__main__":
    import uvicorn
    
    # Get configuration from environment variables
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", 8000))
    reload = os.getenv("API_RELOAD", "true").lower() == "true"
    
    logger.info(f"Starting server on {host}:{port}")
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=reload,
    )
