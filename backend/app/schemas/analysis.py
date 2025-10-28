"""
Pydantic schemas for AnalysisResult model.
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any
from datetime import datetime


class FillerWordsPattern(BaseModel):
    """Filler words pattern details."""

    count: int = 0
    words: Dict[str, int] = Field(default_factory=dict)  # {"um": 5, "uh": 3}
    per_minute: float = 0.0


class HedgingPattern(BaseModel):
    """Hedging language pattern details."""

    count: int = 0
    phrases: Dict[str, int] = Field(default_factory=dict)  # {"I think": 2, "maybe": 1}


class PersuasionKeywords(BaseModel):
    """Persuasion keywords breakdown."""

    call_to_action: int = 0
    power_words: int = 0
    evidence_indicators: int = 0


class CriticalMoment(BaseModel):
    """Critical moment in the speech."""

    timestamp: float = Field(..., description="Timestamp in seconds")
    type: str = Field(..., description="Type of issue (e.g., 'excessive_fillers', 'hedging')")
    severity: int = Field(..., ge=1, le=10, description="Severity score 1-10")
    context: str = Field(..., description="Text snippet showing the issue")
    suggestion: Optional[str] = Field(None, description="Improvement suggestion")


class PatternDetails(BaseModel):
    """Detailed pattern information."""

    filler_words: Optional[FillerWordsPattern] = None
    hedging: Optional[HedgingPattern] = None
    persuasion_keywords: Optional[PersuasionKeywords] = None


class AnalysisResultBase(BaseModel):
    """Base analysis result schema."""

    transcript: Optional[str] = None

    # Overall scores
    overall_score: float = Field(0.0, ge=0.0, le=100.0)
    power_dynamics_score: float = Field(0.0, ge=0.0, le=100.0)
    linguistic_authority_score: float = Field(0.0, ge=0.0, le=100.0)
    vocal_command_score: float = Field(0.0, ge=0.0, le=100.0)
    persuasion_influence_score: float = Field(0.0, ge=0.0, le=100.0)

    # Power Dynamics details
    filler_words_count: int = 0
    filler_words_per_minute: float = 0.0
    hedging_count: int = 0
    upspeak_indicators: int = 0

    # Linguistic Authority details
    passive_voice_ratio: float = 0.0
    average_sentence_length: float = 0.0
    word_diversity_score: float = 0.0
    jargon_overuse_score: float = 0.0

    # Vocal Command details
    words_per_minute: float = 0.0
    average_pause_duration: float = 0.0
    pace_variance: float = 0.0

    # Persuasion Influence details
    story_coherence_score: float = 0.0
    call_to_action_count: int = 0
    power_words_count: int = 0
    evidence_indicators_count: int = 0

    # Detailed patterns
    patterns: Optional[Dict[str, Any]] = None
    critical_moments: Optional[List[Dict[str, Any]]] = Field(default_factory=list)


class AnalysisResultResponse(AnalysisResultBase):
    """Schema for analysis result response (includes ID and timestamps)."""

    id: str
    recording_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Enable ORM mode


class AnalyzeRequest(BaseModel):
    """Request schema for analysis (multipart form with file upload)."""

    # Note: File upload is handled separately via UploadFile in FastAPI
    # This schema is for any additional metadata
    title: Optional[str] = None
    notes: Optional[str] = None
