"""
AnalysisResult model for storing speech analysis data.
"""
from sqlalchemy import Column, String, Float, Integer, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from .base import Base, TimestampMixin


class AnalysisResult(Base, TimestampMixin):
    """
    Analysis result model storing comprehensive speech analysis data.

    Stores scores and detailed patterns from four main analyzers:
    - PowerDynamicsAnalyzer
    - LinguisticAuthorityAnalyzer
    - VocalCommandAnalyzer
    - PersuasionInfluenceAnalyzer
    """

    __tablename__ = "analysis_results"

    id = Column(String(36), primary_key=True)  # Same as recording_id (one-to-one)
    recording_id = Column(String(36), ForeignKey("recordings.id"), nullable=False, unique=True)

    # Transcript
    transcript = Column(Text, nullable=True)  # Full transcription of audio

    # Overall scores (0-100)
    overall_score = Column(Float, nullable=False, default=0.0)
    power_dynamics_score = Column(Float, nullable=False, default=0.0)
    linguistic_authority_score = Column(Float, nullable=False, default=0.0)
    vocal_command_score = Column(Float, nullable=False, default=0.0)
    persuasion_influence_score = Column(Float, nullable=False, default=0.0)

    # Power Dynamics details
    filler_words_count = Column(Integer, nullable=False, default=0)
    filler_words_per_minute = Column(Float, nullable=False, default=0.0)
    hedging_count = Column(Integer, nullable=False, default=0)
    upspeak_indicators = Column(Integer, nullable=False, default=0)

    # Linguistic Authority details
    passive_voice_ratio = Column(Float, nullable=False, default=0.0)
    average_sentence_length = Column(Float, nullable=False, default=0.0)
    word_diversity_score = Column(Float, nullable=False, default=0.0)
    jargon_overuse_score = Column(Float, nullable=False, default=0.0)

    # Vocal Command details
    words_per_minute = Column(Float, nullable=False, default=0.0)
    average_pause_duration = Column(Float, nullable=False, default=0.0)
    pace_variance = Column(Float, nullable=False, default=0.0)

    # Persuasion Influence details
    story_coherence_score = Column(Float, nullable=False, default=0.0)
    call_to_action_count = Column(Integer, nullable=False, default=0)
    power_words_count = Column(Integer, nullable=False, default=0)
    evidence_indicators_count = Column(Integer, nullable=False, default=0)

    # Detailed patterns stored as JSON
    # Format: {"filler_words": {"um": 5, "uh": 3}, "hedging": {"I think": 2}}
    patterns = Column(JSON, nullable=True)

    # Critical moments stored as JSON array
    # Format: [{"timestamp": 12.5, "type": "excessive_fillers", "severity": 8, "context": "..."}]
    critical_moments = Column(JSON, nullable=True)

    # Relationships
    recording = relationship("Recording", back_populates="analysis_result")

    def __repr__(self):
        return f"<AnalysisResult(recording_id='{self.recording_id}', overall_score={self.overall_score})>"
