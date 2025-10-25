# Speech Mastery App

An iOS-based personal AI speech coach app that leverages server-backed AI analysis to enhance users' communication skills.

## Project Overview

This application helps users improve their speech patterns through:
- **Real-time audio recording** with privacy-first design
- **AI-powered speech analysis** detecting filler words, hedging, passive voice, and more
- **Personalized feedback** with daily reports and pattern recognition
- **Secure data handling** with encryption and auto-deletion

## Architecture

- **Frontend**: iOS app built with SwiftUI + Swift 5.9+
- **Backend**: FastAPI server with PostgreSQL database
- **AI Services**: Abstract interfaces for transcription and NLP analysis
- **Infrastructure**: Docker-based local development environment

## Project Structure

```
speech_analyzer/
├── ios/                 # iOS SwiftUI application
├── backend/            # FastAPI backend server
├── docker/             # Docker configuration
├── docs/               # Documentation
└── scripts/            # Utility scripts
```

## Getting Started

### Prerequisites
- macOS with Xcode 15+ (for iOS development)
- Docker Desktop (for backend services)
- Python 3.11+ (for backend development)

### Quick Start

1. **Initialize development environment**:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/setup.sh
   ```

2. **Start Docker services** (backend, database, cache):
   ```bash
   ./scripts/start-docker.sh
   ```

   Services will be available at:
   - Backend API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Database: localhost:5432
   - pgAdmin: http://localhost:5050

3. **Develop iOS app** (open in Xcode):
   ```bash
   open ios/SpeechMastery/SpeechMastery.xcodeproj
   ```

   Then select a `.swift` file and enable Canvas preview (Editor → Canvas)

## Development Roadmap

### Base Prototype (Current)
- ✅ Audio recording with privacy indicators
- ✅ Local storage with UserDefaults + Files
- ✅ Four core speech analyzers
- ✅ Daily reports with scoring and patterns
- ✅ Single-user mode

### Optional Premium Features (Future)
- 🔜 CEO Voice Synthesis
- 🔜 Live Guardian Mode with real-time alerts
- 🔜 Simulation Arena for roleplay practice
- 🔜 Gamification system (XP, streaks, leaderboards)
- 🔜 Pre-Game Prep Mode
- 🔜 Power Language Arsenal
- 🔜 Conversational Chess
- 🔜 Voice Command Training
- 🔜 Success Guarantee System (90-day protocol)

## Documentation

- [API Contract](docs/API_CONTRACT.md) - REST API specification
- [Database Schema](docs/DATABASE_SCHEMA.md) - Data models and relationships
- [Development Guide](docs/DEVELOPMENT_GUIDE.md) - Setup and workflow
- [Architecture](docs/ARCHITECTURE.md) - System design and patterns
- [Optional Features Roadmap](docs/OPTIONAL_FEATURES_ROADMAP.md) - Premium features plan

## Testing

- **iOS**: XCTest framework with mock data
- **Backend**: Pytest with fixtures and integration tests
- **Mock Data**: Sample audio files and API responses included

## Privacy & Security

- NSFileProtectionComplete for file encryption
- Microphone permission management
- Visual recording indicators
- Auto-deletion after 7 days
- Secure HTTPS uploads with authentication

## Contributing

This is a prototype project. For questions or contributions, see the development guide.

## License

Proprietary - All rights reserved
