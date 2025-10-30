#!/usr/bin/env python3
"""
View Analysis - Display detailed analysis for recordings
"""
import requests
import json
import sys

API_URL = "http://localhost:8000/api/v1"
AUTH_TOKEN = "SINGLE_USER_DEV_TOKEN_12345"
HEADERS = {"Authorization": f"Bearer {AUTH_TOKEN}"}


def list_recordings():
    """List all recordings"""
    response = requests.get(f"{API_URL}/recordings", headers=HEADERS)
    data = response.json()

    print(f"\n📚 Total: {data['total']} recordings\n")
    print("="*80)

    for i, rec in enumerate(data['recordings'], 1):
        print(f"{i}. {rec.get('title', 'Untitled')}")
        print(f"   ID: {rec['id']}")
        print(f"   Duration: {rec['duration']:.1f}s | Created: {rec['created_at'][:19]}")
        print()


def view_analysis(recording_id):
    """View detailed analysis for a recording"""
    response = requests.get(
        f"{API_URL}/recordings/{recording_id}/analysis",
        headers=HEADERS
    )

    if response.status_code != 200:
        print(f"❌ Error: {response.status_code} - {response.text}")
        return

    data = response.json()

    print("="*80)
    print("📋 COMPLETE ANALYSIS REPORT")
    print("="*80)

    print("\n📝 TRANSCRIPT")
    print("-"*80)
    transcript = data['transcript']
    if transcript:
        if len(transcript) > 1000:
            print(transcript[:1000] + "...")
            print(f"\n[Full: {len(transcript)} chars, {len(transcript.split())} words]")
        else:
            print(transcript)
    else:
        print("(No transcript)")

    print("\n" + "="*80)
    print("📊 SCORES")
    print("="*80)
    print(f"Overall:              {data['overall_score']:.1f}/100")
    print(f"├─ Power Dynamics:    {data['power_dynamics_score']:.1f}/100")
    print(f"├─ Linguistic:        {data['linguistic_authority_score']:.1f}/100")
    print(f"├─ Vocal Command:     {data['vocal_command_score']:.1f}/100")
    print(f"└─ Persuasion:        {data['persuasion_influence_score']:.1f}/100")

    print("\n" + "="*80)
    print("🎯 POWER DYNAMICS")
    print("="*80)
    print(f"Filler Words:         {data['filler_words_count']} ({data['filler_words_per_minute']}/min)")
    print(f"Hedging Phrases:      {data['hedging_count']}")
    print(f"Upspeak:              {data['upspeak_indicators']}")

    patterns = data.get('patterns', {})
    if patterns.get('filler_words'):
        print("\nFillers Detected:")
        for word, count in sorted(patterns['filler_words'].items(), key=lambda x: x[1], reverse=True):
            print(f"  • '{word}': {count}")

    if patterns.get('hedging'):
        print("\nHedging Detected:")
        for phrase, count in sorted(patterns['hedging'].items(), key=lambda x: x[1], reverse=True):
            print(f"  • '{phrase}': {count}")

    print("\n" + "="*80)
    print("⏱️ CRITICAL MOMENTS")
    print("="*80)

    if data['critical_moments']:
        for i, m in enumerate(data['critical_moments'], 1):
            print(f"\n{i}. [{m['timestamp']:.1f}s] {m['type'].upper()}")
            print(f"   Severity: {m['severity']}/10")
            print(f"   {m['context']}")
            print(f"   💡 {m['suggestion']}")
    else:
        print("\n✨ None detected!")

    print("\n" + "="*80)
    print("📈 METRICS")
    print("="*80)
    print(f"WPM:                  {data['words_per_minute']:.0f}")
    print(f"Pace Variance:        {data['pace_variance']:.1f}")
    print(f"Avg Pause:            {data['average_pause_duration']:.1f}s")
    print(f"Passive Voice:        {data['passive_voice_ratio']:.1%}")
    print(f"Avg Sentence Length:  {data['average_sentence_length']:.1f}")
    print(f"Word Diversity:       {data['word_diversity_score']:.0f}/100")

    print("\n" + "="*80)
    print(f"📅 Created: {data['created_at']}")
    print(f"🆔 ID: {data['recording_id']}")
    print("="*80)


def get_latest_recording_id():
    """Get the ID of the most recent recording"""
    response = requests.get(f"{API_URL}/recordings", headers=HEADERS)
    data = response.json()
    if data['recordings']:
        return data['recordings'][0]['id']
    return None


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 scripts/view_analysis.py --list")
        print("  python3 scripts/view_analysis.py --latest")
        print("  python3 scripts/view_analysis.py <recording_id>")
        sys.exit(1)

    if sys.argv[1] == "--list":
        list_recordings()
    elif sys.argv[1] == "--latest":
        recording_id = get_latest_recording_id()
        if recording_id:
            print(f"📊 Viewing latest recording: {recording_id}\n")
            view_analysis(recording_id)
        else:
            print("❌ No recordings found")
    else:
        recording_id = sys.argv[1]
        print(f"📊 Viewing recording: {recording_id}\n")
        view_analysis(recording_id)
