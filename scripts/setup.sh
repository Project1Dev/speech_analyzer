#!/bin/bash

#
# Setup Script for Speech Mastery Project
#
# Initializes development environment for both iOS and backend.
# Creates virtual environments, installs dependencies, and sets up databases.
#
# Usage: ./scripts/setup.sh (from root or scripts/)
#

set -e  # Exit on error

# Determine project root (works from any directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "Speech Mastery Development Setup"
echo "=================================="
echo ""

# MARK: - Colors for output

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# MARK: - Setup Backend

echo -e "${YELLOW}Setting up Backend...${NC}"
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed${NC}"
    exit 1
fi

python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $python_version"

# Create virtual environment
if [ ! -d "backend/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv backend/venv
else
    echo "Virtual environment already exists"
fi

# Activate virtual environment
source backend/venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
if [ -f "backend/requirements.txt" ]; then
    pip install -r backend/requirements.txt
else
    echo -e "${YELLOW}requirements.txt not found${NC}"
fi

deactivate

echo -e "${GREEN}Backend setup complete${NC}"
echo ""

# MARK: - Setup iOS

echo -e "${YELLOW}Setting up iOS...${NC}"
echo ""

# Check Xcode
if ! command -v xcode-select &> /dev/null; then
    echo -e "${RED}Xcode is not installed${NC}"
    exit 1
fi

echo "Xcode found"

# Check if iOS project exists
if [ -f "ios/SpeechMastery/SpeechMastery.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}iOS project found${NC}"
else
    echo -e "${YELLOW}iOS project not found at expected location${NC}"
fi

echo -e "${GREEN}iOS setup complete${NC}"
echo ""

# MARK: - Docker Setup

echo -e "${YELLOW}Docker Setup Information${NC}"
echo ""
echo "To start Docker containers:"
echo "  docker-compose up -d"
echo ""
echo "Services will be available at:"
echo "  - Backend API: http://localhost:8000"
echo "  - Database (PostgreSQL): localhost:5432"
echo "  - Cache (Redis): localhost:6379"
echo "  - pgAdmin: http://localhost:5050"
echo ""

# MARK: - Summary

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Backend development:"
echo "   cd backend && source venv/bin/activate"
echo ""
echo "2. iOS development:"
echo "   open ios/SpeechMastery/SpeechMastery.xcodeproj"
echo ""
echo "3. Start Docker services:"
echo "   docker-compose up -d"
echo ""

# TODO: Create environment files
# TODO: Initialize database with alembic
# TODO: Download AI models if needed
# TODO: Validate setup completion
