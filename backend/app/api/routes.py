"""
API Routes for Speech Mastery App.

Endpoints:
- POST /analyze - Upload and analyze audio file
- GET /recordings - List user's recordings
- DELETE /recordings/{id} - Delete a recording
- GET /reports/{date} - Get daily report (future)
"""
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Form
from sqlalchemy.orm import Session
from typing import Optional
import uuid
import os
import librosa

from app.core.database import get_db
from app.core.security import get_current_user
from app.core.config import settings
from app.models.user import User
from app.models.recording import Recording
from app.models.analysis_result import AnalysisResult
from app.schemas.recording import RecordingResponse, RecordingListResponse
from app.schemas.analysis import AnalysisResultResponse
from app.schemas.common import MessageResponse
from app.services.analysis_engine import AnalysisEngine

router = APIRouter()

# Initialize analysis engine (singleton pattern)
analysis_engine = AnalysisEngine()


@router.post("/analyze", response_model=AnalysisResultResponse, status_code=201)
async def analyze_audio(
    file: UploadFile = File(..., description="Audio file (m4a, wav, mp3)"),
    title: Optional[str] = Form(None, description="Optional title for the recording"),
    notes: Optional[str] = Form(None, description="Optional notes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Upload and analyze an audio file.

    Process:
    1. Validate file type and size
    2. Save file to disk
    3. Extract audio metadata (duration, sample rate)
    4. Run comprehensive analysis
    5. Store recording and analysis results in database
    6. Return analysis results

    Returns:
        AnalysisResultResponse with comprehensive analysis data
    """
    # Validate file type
    allowed_extensions = {'.m4a', '.wav', '.mp3', '.aac'}
    file_ext = os.path.splitext(file.filename)[1].lower()

    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file_ext}. Allowed: {', '.join(allowed_extensions)}"
        )

    # Generate unique ID and file path
    recording_id = str(uuid.uuid4())
    upload_dir = settings.UPLOAD_DIR
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, f"{recording_id}{file_ext}")

    try:
        # Save uploaded file
        file_size = 0
        with open(file_path, "wb") as f:
            content = await file.read()
            file_size = len(content)
            f.write(content)

        # Validate file size
        if file_size > settings.MAX_UPLOAD_SIZE:
            os.remove(file_path)
            raise HTTPException(
                status_code=413,
                detail=f"File too large. Maximum size: {settings.MAX_UPLOAD_SIZE / 1024 / 1024}MB"
            )

        # Extract audio metadata using librosa
        try:
            audio_data, sample_rate = librosa.load(file_path, sr=None)
            duration = librosa.get_duration(y=audio_data, sr=sample_rate)
        except Exception as e:
            # Fallback: estimate duration if librosa fails
            print(f"Warning: Could not extract exact duration: {e}")
            duration = 30.0  # Default estimate
            sample_rate = 44100

        # Create recording record
        recording = Recording(
            id=recording_id,
            user_id=current_user.id,
            file_path=file_path,
            file_size=file_size,
            duration=duration,
            format=file_ext.lstrip('.'),
            sample_rate=sample_rate,
            title=title,
            notes=notes,
        )

        db.add(recording)
        db.commit()

        # Run analysis
        analysis_result_data = analysis_engine.analyze_audio(
            audio_file_path=file_path,
            duration=duration
        )

        # Create analysis result record
        analysis_result = AnalysisResult(
            id=recording_id,  # Same as recording_id (one-to-one relationship)
            recording_id=recording_id,
            transcript=analysis_result_data["transcript"],
            overall_score=analysis_result_data["overall_score"],
            power_dynamics_score=analysis_result_data["power_dynamics_score"],
            linguistic_authority_score=analysis_result_data["linguistic_authority_score"],
            vocal_command_score=analysis_result_data["vocal_command_score"],
            persuasion_influence_score=analysis_result_data["persuasion_influence_score"],
            filler_words_count=analysis_result_data["filler_words_count"],
            filler_words_per_minute=analysis_result_data["filler_words_per_minute"],
            hedging_count=analysis_result_data["hedging_count"],
            upspeak_indicators=analysis_result_data["upspeak_indicators"],
            passive_voice_ratio=analysis_result_data["passive_voice_ratio"],
            average_sentence_length=analysis_result_data["average_sentence_length"],
            word_diversity_score=analysis_result_data["word_diversity_score"],
            jargon_overuse_score=analysis_result_data["jargon_overuse_score"],
            words_per_minute=analysis_result_data["words_per_minute"],
            average_pause_duration=analysis_result_data["average_pause_duration"],
            pace_variance=analysis_result_data["pace_variance"],
            story_coherence_score=analysis_result_data["story_coherence_score"],
            call_to_action_count=analysis_result_data["call_to_action_count"],
            power_words_count=analysis_result_data["power_words_count"],
            evidence_indicators_count=analysis_result_data["evidence_indicators_count"],
            patterns=analysis_result_data["patterns"],
            critical_moments=analysis_result_data["critical_moments"],
        )

        db.add(analysis_result)
        db.commit()
        db.refresh(analysis_result)

        return analysis_result

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Clean up file on error
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {str(e)}"
        )


@router.get("/recordings", response_model=RecordingListResponse)
async def get_recordings(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get list of user's recordings.

    Query Parameters:
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return

    Returns:
        RecordingListResponse with list of recordings and total count
    """
    # Get recordings for current user
    recordings = db.query(Recording).filter(
        Recording.user_id == current_user.id
    ).order_by(
        Recording.created_at.desc()
    ).offset(skip).limit(limit).all()

    # Get total count
    total = db.query(Recording).filter(
        Recording.user_id == current_user.id
    ).count()

    return {
        "recordings": recordings,
        "total": total
    }


@router.delete("/recordings/{recording_id}", response_model=MessageResponse)
async def delete_recording(
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Delete a recording and its analysis result.

    Path Parameters:
        recording_id: UUID of the recording to delete

    Returns:
        MessageResponse confirming deletion
    """
    # Find recording
    recording = db.query(Recording).filter(
        Recording.id == recording_id,
        Recording.user_id == current_user.id
    ).first()

    if not recording:
        raise HTTPException(
            status_code=404,
            detail="Recording not found"
        )

    # Delete file from disk
    if os.path.exists(recording.file_path):
        try:
            os.remove(recording.file_path)
        except Exception as e:
            print(f"Warning: Could not delete file {recording.file_path}: {e}")

    # Delete from database (cascade will delete analysis_result)
    db.delete(recording)
    db.commit()

    return {
        "message": f"Recording {recording_id} deleted successfully",
        "status": "success"
    }


@router.get("/recordings/{recording_id}/analysis", response_model=AnalysisResultResponse)
async def get_analysis(
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get analysis results for a specific recording.

    Path Parameters:
        recording_id: UUID of the recording

    Returns:
        AnalysisResultResponse with full analysis data
    """
    # Verify recording belongs to user
    recording = db.query(Recording).filter(
        Recording.id == recording_id,
        Recording.user_id == current_user.id
    ).first()

    if not recording:
        raise HTTPException(
            status_code=404,
            detail="Recording not found"
        )

    # Get analysis result
    analysis = db.query(AnalysisResult).filter(
        AnalysisResult.recording_id == recording_id
    ).first()

    if not analysis:
        raise HTTPException(
            status_code=404,
            detail="Analysis not found for this recording"
        )

    return analysis
