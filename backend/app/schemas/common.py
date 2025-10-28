"""
Common Pydantic schemas used across the API.
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TimestampSchema(BaseModel):
    """Base schema with timestamp fields."""

    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Enable ORM mode for SQLAlchemy models


class MessageResponse(BaseModel):
    """Generic message response."""

    message: str
    status: Optional[str] = "success"


class ErrorResponse(BaseModel):
    """Error response schema."""

    error: str
    detail: Optional[str] = None
    status: str = "error"
