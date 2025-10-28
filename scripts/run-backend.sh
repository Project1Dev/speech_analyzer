#!/bin/bash

# Speech Mastery - Backend Runner
# Simple script to start the backend with proper setup
# Works from any directory (root or scripts/)

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Determine project root (works from any directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

cd backend

# Check if venv exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment not found. Running setup first...${NC}"
    bash "$PROJECT_ROOT/scripts/setup.sh"
fi

# Activate venv
source venv/bin/activate

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Speech Mastery Backend - Starting${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Environment:${NC}"
echo "  Python: $(python --version)"
echo "  Location: $(pwd)"
echo ""
echo -e "${BLUE}Service will be available at:${NC}"
echo "  ${GREEN}http://localhost:8000${NC}"
echo "  ${GREEN}http://localhost:8000/docs${NC} (Interactive API)"
echo "  ${GREEN}http://localhost:8000/redoc${NC} (Alternative API docs)"
echo ""
echo -e "${BLUE}Stop the server:${NC}"
echo "  Press ${YELLOW}Ctrl+C${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# Run the backend with hot reload
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000 \
  --log-level info
