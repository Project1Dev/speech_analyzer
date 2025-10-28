"""
Analysis Engine - Orchestrates comprehensive speech analysis.

Coordinates multiple analyzers:
- PowerDynamicsAnalyzer: Filler words, hedging, upspeak
- LinguisticAuthorityAnalyzer: Passive voice, sentence structure
- VocalCommandAnalyzer: Speaking pace, pauses
- PersuasionInfluenceAnalyzer: Storytelling, persuasion techniques

Process:
1. Receive audio file and transcription
2. Run all analyzers in parallel (or sequentially for prototype)
3. Aggregate scores and results
4. Return comprehensive analysis result
"""
from typing import Dict, Optional
import os

from .transcription_service import get_transcription_service
from .power_dynamics_analyzer import PowerDynamicsAnalyzer
from .linguistic_authority_analyzer import LinguisticAuthorityAnalyzer
from .vocal_command_analyzer import VocalCommandAnalyzer
from .persuasion_influence_analyzer import PersuasionInfluenceAnalyzer
from app.core.config import settings


class AnalysisEngine:
    """
    Main analysis orchestrator.

    Coordinates transcription and all analysis services.
    """

    def __init__(self):
        """Initialize all analyzers and services."""
        # Initialize transcription service
        self.transcription_service = get_transcription_service(
            settings.TRANSCRIPTION_SERVICE
        )

        # Initialize all analyzers
        self.power_dynamics_analyzer = PowerDynamicsAnalyzer()
        self.linguistic_authority_analyzer = LinguisticAuthorityAnalyzer()
        self.vocal_command_analyzer = VocalCommandAnalyzer()
        self.persuasion_analyzer = PersuasionInfluenceAnalyzer()

    def analyze_audio(
        self,
        audio_file_path: str,
        duration: float,
        transcript: Optional[str] = None
    ) -> Dict:
        """
        Perform comprehensive analysis on audio file.

        Args:
            audio_file_path: Path to audio file
            duration: Duration in seconds
            transcript: Optional pre-existing transcript (if None, will transcribe)

        Returns:
            Dict containing:
            - transcript: Full transcription
            - overall_score: Aggregate score (0-100)
            - power_dynamics_score: Score from PowerDynamicsAnalyzer
            - linguistic_authority_score: Score from LinguisticAuthorityAnalyzer
            - vocal_command_score: Score from VocalCommandAnalyzer
            - persuasion_influence_score: Score from PersuasionAnalyzer
            - All detailed metrics from each analyzer
            - patterns: Aggregated pattern data
            - critical_moments: Combined list of issues
        """
        # Step 1: Get transcript (if not provided)
        if transcript is None:
            transcript = self.transcription_service.transcribe(audio_file_path)

        # Step 2: Read audio data (for advanced analysis)
        audio_data = None
        try:
            with open(audio_file_path, 'rb') as f:
                audio_data = f.read()
        except Exception as e:
            print(f"Warning: Could not read audio data: {e}")

        # Step 3: Run all analyzers
        power_result = self.power_dynamics_analyzer.analyze(
            transcript, duration, audio_data
        )

        linguistic_result = self.linguistic_authority_analyzer.analyze(
            transcript, duration
        )

        vocal_result = self.vocal_command_analyzer.analyze(
            transcript, duration
        )

        persuasion_result = self.persuasion_analyzer.analyze(
            transcript, duration
        )

        # Step 4: Calculate overall score (weighted average)
        overall_score = self._calculate_overall_score(
            power_result["score"],
            linguistic_result["score"],
            vocal_result["score"],
            persuasion_result["score"]
        )

        # Step 5: Aggregate patterns
        patterns = self._aggregate_patterns(
            power_result,
            linguistic_result,
            vocal_result,
            persuasion_result
        )

        # Step 6: Combine critical moments
        critical_moments = self._combine_critical_moments(
            power_result.get("critical_moments", []),
            linguistic_result.get("critical_moments", []),
            vocal_result.get("critical_moments", []),
            persuasion_result.get("critical_moments", [])
        )

        # Step 7: Return comprehensive result
        return {
            "transcript": transcript,

            # Overall scores
            "overall_score": overall_score,
            "power_dynamics_score": power_result["score"],
            "linguistic_authority_score": linguistic_result["score"],
            "vocal_command_score": vocal_result["score"],
            "persuasion_influence_score": persuasion_result["score"],

            # Power Dynamics details
            "filler_words_count": power_result["filler_words"]["count"],
            "filler_words_per_minute": power_result["filler_words"]["per_minute"],
            "hedging_count": power_result["hedging"]["count"],
            "upspeak_indicators": power_result["upspeak_indicators"],

            # Linguistic Authority details
            "passive_voice_ratio": linguistic_result["passive_voice_ratio"],
            "average_sentence_length": linguistic_result["average_sentence_length"],
            "word_diversity_score": linguistic_result["word_diversity_score"],
            "jargon_overuse_score": linguistic_result["jargon_overuse_score"],

            # Vocal Command details
            "words_per_minute": vocal_result["words_per_minute"],
            "average_pause_duration": vocal_result["average_pause_duration"],
            "pace_variance": vocal_result["pace_variance"],

            # Persuasion Influence details
            "story_coherence_score": persuasion_result["story_coherence_score"],
            "call_to_action_count": persuasion_result["persuasion_keywords"]["call_to_action"],
            "power_words_count": persuasion_result["persuasion_keywords"]["power_words"],
            "evidence_indicators_count": persuasion_result["persuasion_keywords"]["evidence_indicators"],

            # Aggregated data
            "patterns": patterns,
            "critical_moments": critical_moments
        }

    def _calculate_overall_score(
        self,
        power_score: float,
        linguistic_score: float,
        vocal_score: float,
        persuasion_score: float
    ) -> float:
        """
        Calculate weighted overall score.

        For prototype: Equal weights.
        Future: Could have configurable weights based on user goals.
        """
        weights = {
            "power": 0.30,      # 30% - Filler words and confidence
            "linguistic": 0.25,  # 25% - Language authority
            "vocal": 0.20,       # 20% - Speaking pace and rhythm
            "persuasion": 0.25   # 25% - Persuasive techniques
        }

        overall = (
            power_score * weights["power"] +
            linguistic_score * weights["linguistic"] +
            vocal_score * weights["vocal"] +
            persuasion_score * weights["persuasion"]
        )

        return round(overall, 1)

    def _aggregate_patterns(
        self,
        power_result: Dict,
        linguistic_result: Dict,
        vocal_result: Dict,
        persuasion_result: Dict
    ) -> Dict:
        """
        Aggregate pattern data from all analyzers.

        Returns:
            Dict with combined pattern information
        """
        return {
            "filler_words": power_result["filler_words"]["words"],
            "hedging": power_result["hedging"]["phrases"],
            "persuasion_keywords": persuasion_result["persuasion_keywords"]
        }

    def _combine_critical_moments(
        self,
        power_moments: list,
        linguistic_moments: list,
        vocal_moments: list,
        persuasion_moments: list
    ) -> list:
        """
        Combine and sort critical moments by severity.

        Returns:
            Sorted list of critical moments (highest severity first)
        """
        all_moments = (
            power_moments +
            linguistic_moments +
            vocal_moments +
            persuasion_moments
        )

        # Sort by severity (descending)
        all_moments.sort(key=lambda x: x.get("severity", 0), reverse=True)

        # Limit to top 10 most critical moments
        return all_moments[:10]
