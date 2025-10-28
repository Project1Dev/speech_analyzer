"""
Pydantic schemas for request/response validation.

Contains data validation schemas for:
- Recording uploads
- Analysis requests and results
- Common response types
- Error responses
"""
from .common import TimestampSchema, MessageResponse, ErrorResponse
from .recording import (
    RecordingBase,
    RecordingCreate,
    RecordingUpdate,
    RecordingResponse,
    RecordingListResponse,
)
from .analysis import (
    FillerWordsPattern,
    HedgingPattern,
    PersuasionKeywords,
    CriticalMoment,
    PatternDetails,
    AnalysisResultBase,
    AnalysisResultResponse,
    AnalyzeRequest,
)

__all__ = [
    # Common
    "TimestampSchema",
    "MessageResponse",
    "ErrorResponse",
    # Recording
    "RecordingBase",
    "RecordingCreate",
    "RecordingUpdate",
    "RecordingResponse",
    "RecordingListResponse",
    # Analysis
    "FillerWordsPattern",
    "HedgingPattern",
    "PersuasionKeywords",
    "CriticalMoment",
    "PatternDetails",
    "AnalysisResultBase",
    "AnalysisResultResponse",
    "AnalyzeRequest",
]
