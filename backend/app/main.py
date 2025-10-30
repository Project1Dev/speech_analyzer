"""
Speech Mastery FastAPI Application

Main application entry point with FastAPI server configuration.

Responsibilities:
- Configure FastAPI app
- Set up CORS
- Register API routers
- Configure database
- Handle startup/shutdown events

Integration Points:
- api.routes: All endpoint routers
- core.config: Configuration management
- core.database: Database setup
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.core.database import init_db, check_db_connection
from app.core.logging import setup_logging, get_logger
from app.api.routes import router

# Initialize logging
log_level = "DEBUG" if settings.DEBUG else "INFO"
json_logs = settings.ENVIRONMENT == "production"
setup_logging(level=log_level, json_logs=json_logs)

logger = get_logger(__name__)

# MARK: - Startup/Shutdown Events

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan context manager.
    Handles startup and shutdown events.
    """
    # Initialize database
    logger.info("Initializing database...")
    init_db()
    logger.info("Database initialized successfully")

    # Check database connection
    if check_db_connection():
        logger.info("Database connection: OK")
    else:
        logger.warning("Database connection failed")

    # Create upload directory
    import os
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    logger.info(f"Upload directory ready: {settings.UPLOAD_DIR}")

    logger.info("Application startup complete")
    yield

    # Cleanup on shutdown
    logger.info("Application shutdown")

# MARK: - App Creation

app = FastAPI(
    title="Speech Mastery API",
    description="AI-powered speech analysis and coaching API",
    version="1.0.0",
    lifespan=lifespan
)

# MARK: - CORS Configuration

# TODO: Configure CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to iOS app domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MARK: - Route Registration

# Include API router
app.include_router(router, prefix="/api/v1", tags=["api"])

# MARK: - Root Endpoint

@app.get("/")
async def root():
    """
    Root endpoint - health check.
    """
    # TODO: Return basic app info
    return {
        "message": "Speech Mastery API",
        "version": "1.0.0",
        "status": "running"
    }

# MARK: - Health Check

@app.get("/health")
async def health():
    """
    Health check endpoint for load balancers.
    Verifies API and database connectivity.
    """
    db_status = "ok" if check_db_connection() else "error"
    overall_status = "healthy" if db_status == "ok" else "unhealthy"

    return {
        "status": overall_status,
        "api": "ok",
        "database": db_status
    }

# MARK: - TODO: Implementation Tasks
# TODO: Core app setup:
# 1. Connect database initialization
# 2. Register all API routers
# 3. Set up error handlers
# 4. Add request logging middleware
# 5. Configure startup/shutdown events
#
# TODO: CORS configuration:
# 1. Set allowed origins to iOS app only
# 2. Configure credentials handling
# 3. Set allowed methods and headers
#
# TODO: Background tasks:
# 1. Start auto-deletion service on startup
# 2. Start report generation cron job
# 3. Stop all tasks on shutdown
#
# TODO: Error handling:
# 1. Create custom exception handlers
# 2. Return proper HTTP status codes
# 3. Include error messages in responses
#
# TODO: Logging:
# 1. Configure structured logging
# 2. Log all API requests
# 3. Log errors and exceptions
