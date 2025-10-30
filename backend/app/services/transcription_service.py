"""
Transcription service for converting speech to text.

Supports multiple backends:
- Mock: Returns realistic fake transcript for testing
- Whisper: Local Whisper model using faster-whisper
- AssemblyAI: AssemblyAI service (future)
"""
from abc import ABC, abstractmethod
from typing import Optional
import random
import os
import time
from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseTranscriptionService(ABC):
    """Abstract base class for transcription services."""

    @abstractmethod
    def transcribe(self, audio_file_path: str) -> str:
        """
        Transcribe audio file to text.

        Args:
            audio_file_path: Path to audio file

        Returns:
            str: Transcribed text
        """
        pass


class MockTranscriptionService(BaseTranscriptionService):
    """
    Mock transcription service for testing.

    Returns realistic fake transcripts with various speech patterns
    including filler words, hedging language, and other common issues.
    """

    # Sample transcript templates with various patterns
    SAMPLE_TRANSCRIPTS = [
        # High filler words
        "Um, so I think, you know, the main point is, like, we need to, uh, "
        "focus on the customer experience. I mean, it's basically, you know, "
        "the most important thing. Um, we should probably, like, invest more "
        "resources in that area. You know what I mean?",

        # Hedging language
        "I think we might want to consider, perhaps, looking into this opportunity. "
        "It seems like it could be, maybe, a good fit for our strategy. I believe "
        "we should probably discuss this further. It's kind of important, I guess.",

        # Mix of both
        "So, um, I was thinking, you know, that we could, like, maybe try a different "
        "approach. I think it might be, uh, more effective. I mean, sort of like what "
        "we did last quarter, but, you know, slightly different. Does that make sense?",

        # More professional (lower scores)
        "The quarterly results demonstrate strong growth across all key metrics. "
        "Revenue increased by fifteen percent, driven by expanded market share. "
        "We successfully launched three new products and secured partnerships "
        "with five major clients. The team delivered exceptional performance.",

        # Mixed patterns with some issues
        "Okay, so the project is, um, progressing well, I think. We've completed, "
        "like, most of the core features. There are, you know, a few challenges "
        "with the integration, but I believe we can, uh, resolve them. The timeline "
        "seems reasonable, maybe we should add some buffer just in case.",
    ]

    def transcribe(self, audio_file_path: str) -> str:
        """
        Return a random sample transcript.

        In a real implementation, this would analyze the audio file.
        For prototype/testing, returns realistic fake data.
        """
        # For now, return a random transcript
        # In future, could vary based on audio file characteristics
        transcript = random.choice(self.SAMPLE_TRANSCRIPTS)

        return transcript


class WhisperTranscriptionService(BaseTranscriptionService):
    """
    Local Whisper transcription service using faster-whisper.

    faster-whisper is a reimplementation of OpenAI's Whisper model using CTranslate2,
    which is 4x faster than the original implementation with lower memory usage.
    """

    def __init__(
        self,
        model_size: str = "base",
        device: str = "cpu",
        compute_type: str = "int8",
        download_root: Optional[str] = None
    ):
        """
        Initialize Whisper model.

        Args:
            model_size: Model size (tiny, base, small, medium, large)
            device: Device to run on (cpu or cuda)
            compute_type: Computation type (int8, float16, float32)
            download_root: Directory to cache downloaded models
        """
        try:
            from faster_whisper import WhisperModel

            logger.info(f"Loading Whisper model: {model_size} on {device} with {compute_type}")

            # Create model directory if it doesn't exist
            if download_root and not os.path.exists(download_root):
                os.makedirs(download_root, exist_ok=True)
                logger.debug(f"Created model directory: {download_root}")

            # Initialize model
            self.model = WhisperModel(
                model_size,
                device=device,
                compute_type=compute_type,
                download_root=download_root
            )
            self.model_size = model_size
            self.device = device

            logger.info(f"Whisper model loaded successfully: {model_size}")

        except ImportError:
            logger.error("faster-whisper package not found")
            raise ImportError(
                "faster-whisper is not installed. "
                "Install it with: pip install faster-whisper"
            )
        except Exception as e:
            logger.error(f"Failed to initialize Whisper model: {str(e)}")
            raise RuntimeError(f"Failed to initialize Whisper model: {str(e)}")

    def transcribe(self, audio_file_path: str) -> str:
        """
        Transcribe audio file using local Whisper model.

        Args:
            audio_file_path: Path to audio file

        Returns:
            str: Transcribed text

        Raises:
            FileNotFoundError: If audio file doesn't exist
            RuntimeError: If transcription fails
        """
        # Validate file exists
        if not os.path.exists(audio_file_path):
            raise FileNotFoundError(f"Audio file not found: {audio_file_path}")

        try:
            start_time = time.time()
            logger.info(f"Starting transcription: {audio_file_path}")

            # Transcribe audio
            # beam_size: Larger = more accurate but slower (5 is a good balance)
            # word_timestamps: Enable for future word-level timing features
            segments, info = self.model.transcribe(
                audio_file_path,
                beam_size=5,
                word_timestamps=False  # Set to True for word-level timestamps in future
            )

            # Combine all segments into full transcript
            transcript_parts = []
            for segment in segments:
                transcript_parts.append(segment.text)

            transcript = " ".join(transcript_parts).strip()

            elapsed_time = time.time() - start_time

            logger.info(
                f"Transcription completed in {elapsed_time:.2f}s | "
                f"Language: {info.language} ({info.language_probability:.2f}) | "
                f"Length: {len(transcript)} chars"
            )

            return transcript

        except Exception as e:
            logger.error(f"Transcription failed for {audio_file_path}: {str(e)}")
            raise RuntimeError(f"Transcription failed: {str(e)}")


def get_transcription_service(service_type: str = "mock") -> BaseTranscriptionService:
    """
    Factory function to get transcription service instance.

    Args:
        service_type: Type of service ("mock", "whisper", etc.)

    Returns:
        BaseTranscriptionService: Transcription service instance
    """
    if service_type == "mock":
        return MockTranscriptionService()
    elif service_type == "whisper":
        # Import settings here to avoid circular dependency
        from app.core.config import settings

        return WhisperTranscriptionService(
            model_size=settings.WHISPER_MODEL_SIZE,
            device=settings.WHISPER_DEVICE,
            compute_type=settings.WHISPER_COMPUTE_TYPE,
            download_root=settings.WHISPER_MODEL_DIR
        )
    else:
        raise ValueError(f"Unknown transcription service type: {service_type}")
