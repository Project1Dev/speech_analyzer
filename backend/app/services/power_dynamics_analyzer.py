"""
Power Dynamics Speech Analyzer

Analyzes filler words, hedging language, and upspeak patterns.
Identifies linguistic patterns that undermine authority and confidence.

Responsibilities:
- Detect filler words (um, uh, like, you know, etc.)
- Identify hedging language (I think, maybe, possibly, etc.)
- Detect upspeak (rising intonation at end of statements)
- Calculate power dynamics score
- Identify critical moments with suggestions

Scoring:
- Filler words: -1 to -5 points each (count per minute)
- Hedging language: -2 to -4 points each
- Upspeak indicators: -1 to -3 points each
- Score range: 0-100

Integration Points:
- AnalysisEngine: Called as part of comprehensive analysis
- AnalysisResult: Results stored in analysis
- CriticalMomentDetector: Identifies issues with timestamps

OPTIONAL FEATURE: Custom patterns
- Allow users to define additional filler words
- Track personal hedging tendencies
"""

from typing import List, Dict, Tuple
import re
from app.core.logging import get_logger

logger = get_logger(__name__)


class PowerDynamicsAnalyzer:
    """
    Analyzer for power dynamics patterns in speech.
    """

    # MARK: - Filler Words Dictionary

    FILLER_WORDS = {
        "um": 1,
        "uh": 1,
        "like": 1,
        "you know": 2,
        "kind of": 1,
        "sort of": 1,
        "basically": 1,
        "literally": 1,
        "actually": 1,
        "really": 1,
    }

    HEDGING_PHRASES = {
        "i think": 2,
        "maybe": 1,
        "possibly": 1,
        "probably": 1,
        "i feel": 2,
        "in my opinion": 2,
        "it seems": 2,
        "kind of": 1,
        "sort of": 1,
        "i guess": 2,
    }

    def __init__(self):
        """
        Initialize analyzer.
        """
        # TODO: Load custom patterns from database
        pass

    def analyze(
        self,
        transcript: str,
        duration: float,
        audio_data: bytes = None
    ) -> Dict:
        """
        Analyze transcript for power dynamics patterns.

        Args:
            transcript: Full transcript text
            duration: Recording duration in seconds
            audio_data: Optional audio for prosody analysis

        Returns:
            Dict with:
            - score: 0-100 power dynamics score
            - filler_words: Count and breakdown
            - hedging: Count and breakdown
            - upspeak_indicators: Count detected
            - critical_moments: List of issues with timestamps

        Raises:
            ValueError: If inputs are invalid
        """
        # Input validation
        if not transcript or not transcript.strip():
            logger.debug("Empty transcript provided, returning perfect score")
            # Return perfect score for empty transcript (no issues detected)
            return {
                "score": 100.0,
                "filler_words": {"count": 0, "words": {}, "per_minute": 0.0},
                "hedging": {"count": 0, "phrases": {}},
                "upspeak_indicators": 0,
                "critical_moments": []
            }

        if duration <= 0:
            logger.error(f"Invalid duration: {duration}")
            raise ValueError(f"Duration must be positive, got: {duration}")

        # Warn if transcript is very long (potential performance issue)
        word_count = len(transcript.split())
        if word_count > 50000:
            logger.warning(f"Very long transcript ({word_count} words). Analysis may be slow.")

        logger.info(f"Starting PowerDynamics analysis | Words: {word_count} | Duration: {duration:.1f}s")

        # Normalize transcript to lowercase for matching
        normalized = transcript.lower()

        # Detect patterns
        filler_result = self.detect_filler_words(normalized)
        hedging_result = self.detect_hedging_language(normalized)

        # Calculate per-minute rate
        duration_minutes = max(duration / 60.0, 0.1)  # Avoid division by zero
        filler_per_minute = filler_result["count"] / duration_minutes

        # Upspeak detection requires audio analysis (not implemented in prototype)
        upspeak_count = 0

        # Calculate overall score
        score = self.calculate_score(
            filler_result["count"],
            hedging_result["count"],
            upspeak_count,
            duration_minutes
        )

        # Identify critical moments (areas with excessive issues)
        critical_moments = self._identify_critical_moments(
            transcript,
            filler_result["words"],
            hedging_result["phrases"],
            duration
        )

        logger.info(
            f"PowerDynamics analysis complete | "
            f"Score: {score:.1f} | "
            f"Fillers: {filler_result['count']} ({filler_per_minute:.1f}/min) | "
            f"Hedging: {hedging_result['count']} | "
            f"Critical moments: {len(critical_moments)}"
        )

        return {
            "score": score,
            "filler_words": {
                "count": filler_result["count"],
                "words": filler_result["words"],
                "per_minute": round(filler_per_minute, 1)
            },
            "hedging": {
                "count": hedging_result["count"],
                "phrases": hedging_result["phrases"]
            },
            "upspeak_indicators": upspeak_count,
            "critical_moments": critical_moments
        }

    def detect_filler_words(self, transcript: str) -> Dict:
        """
        Detect filler words in transcript.

        Returns:
            Dict with count and word breakdown
        """
        word_counts = {}
        total_count = 0

        # Check for multi-word phrases first (e.g., "you know")
        for phrase, weight in sorted(self.FILLER_WORDS.items(), key=lambda x: len(x[0]), reverse=True):
            count = transcript.count(phrase)
            if count > 0:
                word_counts[phrase] = count
                total_count += count

        return {
            "count": total_count,
            "words": word_counts
        }

    def detect_hedging_language(self, transcript: str) -> Dict:
        """
        Detect hedging language.

        Returns:
            Dict with count and phrase breakdown
        """
        phrase_counts = {}
        total_count = 0

        # Check for hedging phrases
        for phrase, weight in sorted(self.HEDGING_PHRASES.items(), key=lambda x: len(x[0]), reverse=True):
            count = transcript.count(phrase)
            if count > 0:
                phrase_counts[phrase] = count
                total_count += count

        return {
            "count": total_count,
            "phrases": phrase_counts
        }

    def analyze_prosody(self, audio_data: bytes, transcript: str) -> int:
        """
        Analyze audio prosody for upspeak patterns.

        TODO: Implement with audio analysis library
        """
        # TODO: Extract prosody features from audio
        # TODO: Detect rising intonation at sentence ends
        # TODO: Count upspeak occurrences
        # TODO: Return count
        pass

    def calculate_score(
        self,
        filler_count: int,
        hedging_count: int,
        upspeak_count: int,
        duration_minutes: float
    ) -> float:
        """
        Calculate power dynamics score.

        Scoring algorithm:
        - Start at 100
        - Deduct points for fillers per minute
        - Deduct points for hedging phrases
        - Deduct points for upspeak
        - Clamp to 0-100 range

        Args:
            filler_count: Total filler words detected
            hedging_count: Total hedging phrases detected
            upspeak_count: Total upspeak instances
            duration_minutes: Duration in minutes

        Returns:
            float: Score from 0-100
        """
        score = 100.0

        # Penalty for filler words (scaled by duration)
        fillers_per_minute = filler_count / duration_minutes
        if fillers_per_minute > 10:
            score -= 30  # Severe
        elif fillers_per_minute > 5:
            score -= 20  # High
        elif fillers_per_minute > 2:
            score -= 10  # Moderate
        elif fillers_per_minute > 0:
            score -= 5   # Low

        # Penalty for hedging language
        hedging_per_minute = hedging_count / duration_minutes
        if hedging_per_minute > 5:
            score -= 25  # Severe
        elif hedging_per_minute > 3:
            score -= 15  # High
        elif hedging_per_minute > 1:
            score -= 8   # Moderate
        elif hedging_per_minute > 0:
            score -= 3   # Low

        # Penalty for upspeak (future implementation)
        score -= upspeak_count * 2

        # Clamp to valid range
        return max(0.0, min(100.0, score))

    def _find_word_positions(self, transcript: str, pattern: str) -> List[int]:
        """
        Find all positions (in characters) where a pattern occurs in the transcript.

        Args:
            transcript: Full transcript (lowercase)
            pattern: Word or phrase to find (lowercase)

        Returns:
            List of character positions where pattern was found
        """
        positions = []
        # Use word boundaries to avoid partial matches
        regex_pattern = r'\b' + re.escape(pattern) + r'\b'

        for match in re.finditer(regex_pattern, transcript, re.IGNORECASE):
            positions.append(match.start())

        return positions

    def _calculate_timestamp(
        self,
        char_position: int,
        transcript: str,
        duration: float
    ) -> float:
        """
        Calculate approximate timestamp based on character position in transcript.

        Assumes speech is relatively evenly paced throughout recording.

        Args:
            char_position: Character position in transcript
            transcript: Full transcript
            duration: Audio duration in seconds

        Returns:
            float: Estimated timestamp in seconds
        """
        if len(transcript) == 0:
            return 0.0

        # Calculate relative position (0.0 to 1.0)
        relative_position = char_position / len(transcript)

        # Scale to duration
        timestamp = relative_position * duration

        # Round to 1 decimal place
        return round(timestamp, 1)

    def _identify_critical_moments(
        self,
        transcript: str,
        filler_words: Dict[str, int],
        hedging_phrases: Dict[str, int],
        duration: float
    ) -> List[Dict]:
        """
        Identify critical moments where issues are concentrated.

        Now includes accurate timestamps based on word positions.

        Args:
            transcript: Full transcript (lowercase)
            filler_words: Dict of filler word counts
            hedging_phrases: Dict of hedging phrase counts
            duration: Audio duration in seconds

        Returns:
            List of critical moment dicts with type, severity, context, timestamp
        """
        critical_moments = []

        # Find most common filler word with actual positions
        if filler_words:
            most_common_filler = max(filler_words.items(), key=lambda x: x[1])
            if most_common_filler[1] > 3:  # More than 3 occurrences
                # Find first occurrence for timestamp
                positions = self._find_word_positions(transcript, most_common_filler[0])
                timestamp = 0.0
                if positions:
                    timestamp = self._calculate_timestamp(positions[0], transcript, duration)

                severity = min(10, most_common_filler[1])
                critical_moments.append({
                    "timestamp": timestamp,
                    "type": "excessive_fillers",
                    "severity": severity,
                    "context": f"Repeated use of '{most_common_filler[0]}' ({most_common_filler[1]} times)",
                    "suggestion": f"Reduce use of '{most_common_filler[0]}'. Pause instead."
                })

        # Find most common hedging phrase with actual positions
        if hedging_phrases:
            most_common_hedge = max(hedging_phrases.items(), key=lambda x: x[1])
            if most_common_hedge[1] > 2:  # More than 2 occurrences
                # Find first occurrence for timestamp
                positions = self._find_word_positions(transcript, most_common_hedge[0])
                timestamp = 0.0
                if positions:
                    timestamp = self._calculate_timestamp(positions[0], transcript, duration)

                severity = min(10, most_common_hedge[1] + 2)
                critical_moments.append({
                    "timestamp": timestamp,
                    "type": "hedging",
                    "severity": severity,
                    "context": f"Frequent hedging with '{most_common_hedge[0]}' ({most_common_hedge[1]} times)",
                    "suggestion": f"Speak with more certainty. Remove '{most_common_hedge[0]}'."
                })

        # Sort by timestamp
        critical_moments.sort(key=lambda x: x["timestamp"])

        return critical_moments

# MARK: - TODO: Implementation Tasks
# TODO: Core analysis:
# 1. Implement filler word detection
# 2. Implement hedging language detection
# 3. Add prosody analysis for upspeak
# 4. Create scoring algorithm
# 5. Test with sample transcripts
#
# TODO: Pattern detection:
# 1. Create detailed filler words dictionary
# 2. Add hedging phrases database
# 3. Implement pattern matching
# 4. Handle variations and contractions
#
# TODO: Critical moments:
# 1. Track timestamps for detected patterns
# 2. Create actionable suggestions
# 3. Rank by severity
# 4. Provide examples and alternatives
#
# TODO: Testing:
# 1. Write unit tests for pattern detection
# 2. Test scoring algorithm accuracy
# 3. Validate against sample speeches
# 4. Test edge cases
#
# TODO: When implementing OPTIONAL FEATURE: Custom patterns:
# 1. Allow users to define custom filler words
# 2. Track personal hedging tendencies
# 3. Provide personalized recommendations
# 4. Store custom patterns in database
