#!/bin/bash

# Speech Mastery - Setup Test Script
# Verifies that everything is configured correctly

set -e

echo "🧪 Testing Speech Mastery Setup"
echo "==============================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0
PASSED=0

# Helper functions
test_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test 1: Python version
echo -e "${BLUE}Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 9 ]; then
        test_pass "Python $PYTHON_VERSION (3.9+ required)"
    else
        test_fail "Python version $PYTHON_VERSION (need 3.9+)"
    fi
else
    test_fail "Python3 not found"
fi

echo ""

# Test 2: Backend structure
echo -e "${BLUE}Checking backend files...${NC}"

if [ -f "backend/requirements.txt" ]; then
    test_pass "requirements.txt exists"
else
    test_fail "requirements.txt not found"
fi

if [ -f "backend/app/main.py" ]; then
    test_pass "app/main.py exists"
else
    test_fail "app/main.py not found"
fi

if [ -d "backend/app/services" ]; then
    COUNT=$(ls backend/app/services/*.py 2>/dev/null | wc -l)
    test_pass "Found $COUNT service files"
else
    test_fail "services directory not found"
fi

echo ""

# Test 3: iOS structure
echo -e "${BLUE}Checking iOS files...${NC}"

if [ -f "ios/SpeechMastery/SpeechMastery.xcodeproj/project.pbxproj" ]; then
    test_pass "Xcode project exists"
else
    test_fail "Xcode project not found"
fi

if [ -d "ios/SpeechMastery/Views" ]; then
    VIEW_COUNT=$(ls ios/SpeechMastery/Views/*.swift 2>/dev/null | wc -l)
    test_pass "Found $VIEW_COUNT view files"
else
    test_fail "Views directory not found"
fi

if [ -d "ios/SpeechMastery/ViewModels" ]; then
    VM_COUNT=$(ls ios/SpeechMastery/ViewModels/*.swift 2>/dev/null | wc -l)
    test_pass "Found $VM_COUNT ViewModel files"
else
    test_fail "ViewModels directory not found"
fi

echo ""

# Test 4: GitHub Actions
echo -e "${BLUE}Checking GitHub Actions workflows...${NC}"

if [ -f ".github/workflows/build-ios.yml" ]; then
    test_pass "iOS build workflow configured"
else
    test_fail "iOS build workflow not found"
fi

if [ -f ".github/workflows/test-backend.yml" ]; then
    test_pass "Backend test workflow configured"
else
    test_fail "Backend test workflow not found"
fi

echo ""

# Test 5: Docker
echo -e "${BLUE}Checking Docker setup...${NC}"

if command -v docker &> /dev/null; then
    test_pass "Docker installed"

    if command -v docker-compose &> /dev/null; then
        test_pass "Docker Compose installed"
    else
        test_warn "Docker Compose not installed (optional)"
    fi
else
    test_warn "Docker not installed (optional for development)"
fi

if [ -f "docker-compose.yml" ]; then
    test_pass "docker-compose.yml configured"
else
    test_warn "docker-compose.yml not found (optional)"
fi

echo ""

# Test 6: Virtual environment
echo -e "${BLUE}Checking Python virtual environment...${NC}"

if [ -d "backend/venv" ]; then
    test_pass "Virtual environment exists"

    # Check if FastAPI is installed
    if backend/venv/bin/python -c "import fastapi" 2>/dev/null; then
        test_pass "FastAPI is installed"
    else
        test_warn "FastAPI not installed in venv (run quick-start.sh)"
    fi
else
    test_warn "Virtual environment not created yet (run quick-start.sh)"
fi

echo ""

# Test 7: Configuration
echo -e "${BLUE}Checking configuration...${NC}"

if [ -f "backend/.env" ]; then
    test_pass "backend/.env file exists"

    if grep -q "SINGLE_USER_TOKEN" backend/.env; then
        test_pass "SINGLE_USER_TOKEN is configured"
    fi
else
    test_warn "backend/.env not created (will be created by quick-start.sh)"
fi

echo ""

# Test 8: Documentation
echo -e "${BLUE}Checking documentation...${NC}"

if [ -f "SETUP.md" ]; then
    test_pass "SETUP.md guide available"
else
    test_fail "SETUP.md not found"
fi

if [ -f "CLAUDE.md" ]; then
    test_pass "CLAUDE.md documentation available"
else
    test_warn "CLAUDE.md not found (optional)"
fi

echo ""
echo "==============================="
echo -e "${GREEN}Test Results${NC}"
echo "==============================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Run: ${GREEN}bash quick-start.sh${NC}"
    echo "2. Then: ${GREEN}bash run-backend.sh${NC}"
    echo "3. Open: ${GREEN}http://localhost:8000/docs${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please review the errors above.${NC}"
    echo ""
    echo -e "${YELLOW}To fix issues:${NC}"
    echo "1. Install missing dependencies"
    echo "2. Run: ${GREEN}bash quick-start.sh${NC}"
    echo "3. Check SETUP.md for detailed instructions"
    exit 1
fi
