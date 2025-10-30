"""
Application configuration and settings.
"""
from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Speech Mastery API"
    VERSION: str = "1.0.0"

    # Database Configuration
    # Default: SQLite for local development (no server needed)
    # For PostgreSQL with psycopg3: postgresql+psycopg://user:pass@localhost/dbname
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite:///./speech_mastery.db"
    )

    # Authentication (single-user prototype)
    SINGLE_USER_TOKEN: str = os.getenv("SINGLE_USER_TOKEN", "SINGLE_USER_DEV_TOKEN_12345")

    # File Upload Configuration
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "/tmp/speech_mastery_uploads")
    MAX_UPLOAD_SIZE: int = 100 * 1024 * 1024  # 100MB

    # CORS Configuration
    BACKEND_CORS_ORIGINS: list[str] = ["*"]  # In production, restrict this

    # Feature Flags (for future use)
    ENABLE_CEO_VOICE: bool = False
    ENABLE_LIVE_GUARDIAN: bool = False
    ENABLE_SIMULATION_ARENA: bool = False

    # Service Configuration (for extensibility)
    TRANSCRIPTION_SERVICE: str = os.getenv("TRANSCRIPTION_SERVICE", "mock")  # mock, whisper, etc.
    NLP_SERVICE: str = os.getenv("NLP_SERVICE", "basic")  # basic, spacy, openai, etc.

    # Whisper Configuration
    WHISPER_MODEL_SIZE: str = os.getenv("WHISPER_MODEL_SIZE", "base")  # tiny, base, small, medium, large
    WHISPER_DEVICE: str = os.getenv("WHISPER_DEVICE", "cpu")  # cpu or cuda
    WHISPER_COMPUTE_TYPE: str = os.getenv("WHISPER_COMPUTE_TYPE", "int8")  # int8, float16, float32
    WHISPER_MODEL_DIR: str = os.getenv("WHISPER_MODEL_DIR", "./models")  # Directory to cache models

    # Redis Configuration (for caching and background tasks)
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")

    # Environment Configuration
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")  # development, testing, production
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    class Config:
        case_sensitive = True
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields not defined in Settings


# Global settings instance
settings = Settings()
