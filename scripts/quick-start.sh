#!/bin/bash

# Speech Mastery Quick Start Script
# This script sets up the backend and starts it on Linux
# Works from any directory (root or scripts/)

set -e

# Determine project root (works from any directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "🚀 Speech Mastery - Quick Start"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check Python is installed
echo -e "${BLUE}Checking Python...${NC}"
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.9 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✅ Python $PYTHON_VERSION found${NC}"
echo ""

# Navigate to backend
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${BLUE}Creating virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${GREEN}✅ Virtual environment already exists${NC}"
fi

echo ""

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"

echo ""

# Install/upgrade pip
echo -e "${BLUE}Upgrading pip...${NC}"
pip install --upgrade pip --quiet
echo -e "${GREEN}✅ Pip upgraded${NC}"

echo ""

# Install dependencies
echo -e "${BLUE}Installing dependencies from requirements.txt...${NC}"
if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found"
    exit 1
fi

pip install -r requirements.txt --quiet
echo -e "${GREEN}✅ Dependencies installed${NC}"

echo ""

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${BLUE}Creating .env configuration file...${NC}"
    cat > .env << 'EOF'
DATABASE_URL=sqlite:///./test.db
REDIS_URL=redis://localhost:6379
SINGLE_USER_TOKEN=SINGLE_USER_DEV_TOKEN_12345
ENVIRONMENT=development
UPLOAD_DIR=./uploads
LOG_LEVEL=info
EOF
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

echo ""

# Create uploads directory
mkdir -p uploads
echo -e "${GREEN}✅ Upload directory ready${NC}"

echo ""

# Test imports
echo -e "${BLUE}Testing Python imports...${NC}"
python3 << 'PYEOF'
try:
    from app.main import app
    print("✅ FastAPI app imports successfully")
    from app.models import User, Recording, AnalysisResult
    print("✅ Database models import successfully")
    from app.services.analysis_engine import AnalysisEngine
    print("✅ Analysis engine imports successfully")
except Exception as e:
    print(f"❌ Import failed: {e}")
    exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo "❌ Import test failed"
    exit 1
fi

echo ""
echo "================================"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "================================"
echo ""
echo -e "${YELLOW}To start the backend, run:${NC}"
echo "  source backend/venv/bin/activate"
echo "  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo -e "${YELLOW}Or use the auto-start wrapper:${NC}"
echo "  ./run-backend.sh"
echo ""
echo -e "${YELLOW}Then open:${NC}"
echo "  http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}API Documentation will be available!${NC}"
echo ""
