#!/bin/bash
# View Analysis - Display detailed analysis for a recording

set -e

API_URL="http://localhost:8000/api/v1"
AUTH_TOKEN="SINGLE_USER_DEV_TOKEN_12345"

if [ -z "$1" ]; then
    echo "Usage: $0 <recording_id>"
    echo ""
    echo "To list all recordings:"
    echo "  $0 --list"
    echo ""
    echo "To view the latest:"
    echo "  $0 --latest"
    exit 1
fi

if [ "$1" == "--list" ]; then
    echo "📚 Listing all recordings..."
    curl -s "${API_URL}/recordings" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'\nTotal: {data[\"total\"]} recordings\n')
print('='*80)
for i, rec in enumerate(data['recordings'], 1):
    print(f'{i}. {rec.get(\"title\", \"Untitled\")}')
    print(f'   ID: {rec[\"id\"]}')
    print(f'   Duration: {rec[\"duration\"]:.1f}s | Created: {rec[\"created_at\"][:19]}')
    print()
"
    exit 0
fi

if [ "$1" == "--latest" ]; then
    RECORDING_ID=$(curl -s "${API_URL}/recordings" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data['recordings']:
    print(data['recordings'][0]['id'])
")
else
    RECORDING_ID="$1"
fi

echo "📊 Fetching analysis for: $RECORDING_ID"
echo ""

curl -s "${API_URL}/recordings/${RECORDING_ID}/analysis" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" | python3 << 'EOF'
import json, sys

try:
    data = json.load(sys.stdin)
except:
    print("❌ Error: Recording not found or invalid ID")
    sys.exit(1)

print("="*80)
print("📋 COMPLETE ANALYSIS REPORT")
print("="*80)

print("\n📝 TRANSCRIPT")
print("-"*80)
transcript = data['transcript']
if transcript:
    if len(transcript) > 500:
        print(transcript[:500] + "...")
        print(f"\n[Full: {len(transcript)} chars, {len(transcript.split())} words]")
    else:
        print(transcript if transcript else "(Empty transcript)")
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
EOF
