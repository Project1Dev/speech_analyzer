# How to View Analysis Results

## Quick Reference

### 📋 View Latest Analysis
```bash
python3 scripts/view_analysis.py --latest
```

### 📚 List All Recordings
```bash
python3 scripts/view_analysis.py --list
```

### 🔍 View Specific Recording
```bash
python3 scripts/view_analysis.py <recording_id>
```

---

## Detailed Methods

### Method 1: Python Viewer Script (Recommended)

The easiest way to view detailed analysis:

```bash
cd /home/voldemort/hacking/projects/speech_analyzer

# View the latest recording analysis
python3 scripts/view_analysis.py --latest

# List all your recordings
python3 scripts/view_analysis.py --list

# View a specific recording by ID
python3 scripts/view_analysis.py 260882dd-073d-422f-8fb2-c6616ccc0667
```

**Output includes:**
- ✅ Full transcript
- ✅ All scores breakdown
- ✅ Power dynamics analysis (fillers, hedging)
- ✅ Critical moments with timestamps
- ✅ Detailed metrics (WPM, pauses, vocabulary, etc.)

---

### Method 2: Direct API Queries

#### Get Analysis by Recording ID
```bash
curl http://localhost:8000/api/v1/recordings/{RECORDING_ID}/analysis \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  | python3 -m json.tool
```

#### List All Recordings
```bash
curl http://localhost:8000/api/v1/recordings \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  | python3 -m json.tool
```

#### Upload New Audio for Analysis
```bash
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  -F "file=@your_audio.m4a" \
  -F "title=My Recording" \
  | python3 -m json.tool
```

---

### Method 3: Database Direct Query

Connect to PostgreSQL:
```bash
docker exec -it speech_mastery_postgres psql -U speech_mastery -d speech_mastery_db
```

**Query recent analyses:**
```sql
SELECT
    r.title,
    r.duration,
    a.overall_score,
    a.power_dynamics_score,
    a.filler_words_count,
    a.filler_words_per_minute,
    a.hedging_count,
    a.created_at
FROM recordings r
JOIN analysis_results a ON r.id = a.recording_id
ORDER BY a.created_at DESC
LIMIT 10;
```

**Get full transcript:**
```sql
SELECT transcript
FROM analysis_results
WHERE recording_id = 'YOUR_RECORDING_ID';
```

**View patterns JSON:**
```sql
SELECT patterns, critical_moments
FROM analysis_results
WHERE recording_id = 'YOUR_RECORDING_ID';
```

---

### Method 4: Check Logs

View backend logs for detailed processing information:

```bash
# View logs in real-time
docker-compose logs -f backend

# View recent logs
docker-compose logs backend --tail 100

# Search for specific analysis
docker-compose logs backend | grep "PowerDynamics"

# View saved log files
cat backend/logs/app.log
```

**Log locations:**
- Container logs: `docker-compose logs backend`
- File logs: `backend/logs/app.log`

---

## Understanding the Output

### Scores (0-100 scale)

- **Overall Score**: Weighted average of all categories
- **Power Dynamics**: Filler words, hedging, upspeak (95-100 = excellent)
- **Linguistic Authority**: Vocabulary, sentence structure (70-85 = good)
- **Vocal Command**: Pace, pauses (80-90 = good)
- **Persuasion**: Call-to-actions, power words (75-85 = good)

### Power Dynamics Breakdown

- **Filler Words**: um, uh, like, you know, etc.
  - < 2/min = Excellent
  - 2-5/min = Good
  - 5-10/min = Needs improvement
  - > 10/min = Poor

- **Hedging Phrases**: I think, maybe, possibly, etc.
  - 0-1 = Excellent
  - 2-3 = Good
  - > 3 = Needs improvement

### Critical Moments

Shows specific timestamps where issues are concentrated:
- **Timestamp**: When in the recording
- **Type**: excessive_fillers, hedging, pace_issue, etc.
- **Severity**: 1-10 scale
- **Context**: What was detected
- **Suggestion**: How to improve

---

## API Endpoints

Base URL: `http://localhost:8000/api/v1`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/analyze` | POST | Upload and analyze audio |
| `/recordings` | GET | List all recordings |
| `/recordings/{id}/analysis` | GET | Get detailed analysis |
| `/recordings/{id}` | DELETE | Delete a recording |

**Authentication**: All endpoints require header:
```
Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345
```

---

## Troubleshooting

### "Recording not found"
- Check the recording ID is correct
- Use `--list` to see available recordings

### "Connection refused"
- Ensure backend is running: `docker-compose ps`
- Check backend health: `curl http://localhost:8000/health`

### Empty transcript
- Audio file may not contain speech
- Check logs: `docker-compose logs backend | grep Whisper`

---

## Quick Tips

1. **Save analysis to file:**
   ```bash
   python3 scripts/view_analysis.py --latest > analysis_report.txt
   ```

2. **Compare recordings:**
   ```bash
   python3 scripts/view_analysis.py <ID1> > rec1.txt
   python3 scripts/view_analysis.py <ID2> > rec2.txt
   diff rec1.txt rec2.txt
   ```

3. **Extract just the transcript:**
   ```bash
   curl -s http://localhost:8000/api/v1/recordings/{ID}/analysis \
     -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
     | python3 -c "import json,sys; print(json.load(sys.stdin)['transcript'])"
   ```

4. **Monitor analysis in real-time:**
   ```bash
   docker-compose logs -f backend | grep -E "(Transcription|PowerDynamics|Analysis)"
   ```

---

## Example Workflow

```bash
# 1. Upload and analyze audio
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
  -F "file=@my_speech.m4a" \
  -F "title=Practice Speech"

# 2. View the analysis
python3 scripts/view_analysis.py --latest

# 3. Review logs for details
docker-compose logs backend | grep "PowerDynamics"

# 4. Query database for trends
docker exec -it speech_mastery_postgres psql -U speech_mastery -d speech_mastery_db \
  -c "SELECT title, overall_score, filler_words_per_minute FROM recordings r JOIN analysis_results a ON r.id = a.recording_id ORDER BY a.created_at DESC LIMIT 5;"
```
