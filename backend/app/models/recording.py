"""
Recording model for audio file metadata.
"""
from sqlalchemy import Column, String, Integer, Float, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base, TimestampMixin
import uuid


class Recording(Base, TimestampMixin):
    """Recording model storing audio file metadata and relationships."""

    __tablename__ = "recordings"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # File information
    file_path = Column(String(500), nullable=False)  # Server-side storage path
    file_size = Column(Integer, nullable=False)  # Size in bytes
    duration = Column(Float, nullable=False)  # Duration in seconds

    # Audio format metadata
    format = Column(String(10), default="m4a")  # Audio format (m4a, wav, etc.)
    sample_rate = Column(Integer, nullable=True)  # Sample rate in Hz

    # Optional metadata
    title = Column(String(200), nullable=True)  # User-provided title
    notes = Column(String(1000), nullable=True)  # User notes

    # Relationships
    user = relationship("User", backref="recordings")
    analysis_result = relationship("AnalysisResult", back_populates="recording", uselist=False, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Recording(id='{self.id}', duration={self.duration}s, size={self.file_size} bytes)>"
