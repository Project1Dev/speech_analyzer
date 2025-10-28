"""
Transcription service for converting speech to text.

Supports multiple backends:
- Mock: Returns realistic fake transcript for testing
- Whisper: OpenAI Whisper API (future)
- AssemblyAI: AssemblyAI service (future)
"""
from abc import ABC, abstractmethod
from typing import Optional
import random


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
    Whisper API transcription service (placeholder for future implementation).
    """

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        # TODO: Initialize Whisper client

    def transcribe(self, audio_file_path: str) -> str:
        """Transcribe using OpenAI Whisper API."""
        # TODO: Implement Whisper API call
        raise NotImplementedError("Whisper transcription not yet implemented")


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
        return WhisperTranscriptionService()
    else:
        raise ValueError(f"Unknown transcription service type: {service_type}")
