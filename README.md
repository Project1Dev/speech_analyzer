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
│   ├── SpeechMastery/  # Main app code
│   └── project.yml     # XcodeGen configuration
├── backend/            # FastAPI backend server
│   ├── app/           # Application code
│   ├── alembic/       # Database migrations
│   └── show_api_url.sh # Helper to find backend IP
├── docs/              # Documentation
│   ├── DEVELOPMENT_GUIDE.md
│   ├── MACOS_VM_SETUP.md (for dual-VM setup)
│   └── [other docs]
├── scripts/           # Utility scripts
├── CLAUDE.md         # Instructions for Claude Code
└── README.md         # This file
```

## Getting Started

### Prerequisites

**Dual-VM Setup (Recommended):**
- **Linux VM**: Docker + Python 3.9+ (backend development)
- **macOS VM**: Xcode 15+ + XcodeGen (iOS development)
- See [MACOS_VM_SETUP.md](docs/MACOS_VM_SETUP.md) for detailed instructions

**Single Machine:**
- macOS with Xcode 15+ (for iOS development)
- Docker Desktop (for backend services)
- Python 3.9+ (for backend development)

### Quick Start

1. **Start backend** (on Linux VM or local):
   ```bash
   docker-compose up -d
   ```

2. **Generate iOS project** (on macOS VM or local):
   ```bash
   cd ios
   xcodegen generate
   open SpeechMastery.xcodeproj
   ```

3. **Configure iOS app** to point to backend:
   - Edit `ios/SpeechMastery/Utilities/Constants.swift`
   - Set `baseURL` to your backend IP (or `localhost:8000`)

Backend will be available at:
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database: localhost:5432

## Current Status

This is an **early prototype** with:
- 🏗️ Backend infrastructure (FastAPI, Docker, PostgreSQL)
- 🏗️ iOS app structure (SwiftUI, MVVM architecture)
- 🏗️ Four speech analyzer skeletons
- 🏗️ Database schema and migrations
- ⚠️ **Not yet functional** - most features are TODO

## Documentation

**For Development:**
- [DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md) - Complete setup and workflow
- [MACOS_VM_SETUP.md](docs/MACOS_VM_SETUP.md) - macOS VM setup for dual-VM workflow
- [CLAUDE.md](CLAUDE.md) - Project context for Claude Code

**For Reference:**
- [API_CONTRACT.md](docs/API_CONTRACT.md) - REST API specification
- [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) - Data models
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design

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
