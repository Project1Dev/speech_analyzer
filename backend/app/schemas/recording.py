"""
Pydantic schemas for Recording model.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class RecordingBase(BaseModel):
    """Base recording schema with common fields."""

    file_path: str
    file_size: int = Field(..., ge=0, description="File size in bytes")
    duration: float = Field(..., ge=0.0, description="Duration in seconds")
    format: Optional[str] = "m4a"
    sample_rate: Optional[int] = None
    title: Optional[str] = None
    notes: Optional[str] = None


class RecordingCreate(RecordingBase):
    """Schema for creating a new recording."""
    pass


class RecordingUpdate(BaseModel):
    """Schema for updating a recording."""

    title: Optional[str] = None
    notes: Optional[str] = None


class RecordingResponse(RecordingBase):
    """Schema for recording response (includes ID and timestamps)."""

    id: str
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Enable ORM mode


class RecordingListResponse(BaseModel):
    """Schema for list of recordings."""

    recordings: list[RecordingResponse]
    total: int
