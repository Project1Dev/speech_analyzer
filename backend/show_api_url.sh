#!/bin/bash

################################################################################
# show_api_url.sh
#
# Helper script to display the backend API URL for connecting from iOS app
# on a different VM or physical device.
#
# Usage:
#   ./show_api_url.sh
#
################################################################################

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Backend API URL Helper${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if backend is running
echo -e "${YELLOW}Checking backend status...${NC}"
if command -v docker-compose &> /dev/null; then
    if docker-compose ps | grep -q "speech_mastery_backend.*Up"; then
        echo -e "${GREEN}✓ Backend is running${NC}"
    else
        echo -e "${YELLOW}⚠ Backend is not running${NC}"
        echo "  Start it with: docker-compose up -d"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ docker-compose not found${NC}"
    echo "  Make sure Docker is installed"
    echo ""
fi

# Get IP addresses
echo -e "${YELLOW}Finding IP addresses...${NC}"
echo ""

# Method 1: hostname -I (most reliable)
if command -v hostname &> /dev/null; then
    IPS=$(hostname -I)
    if [ -n "$IPS" ]; then
        echo -e "${GREEN}IP Addresses found:${NC}"
        for ip in $IPS; do
            # Skip localhost and Docker bridge IPs
            if [[ ! $ip =~ ^127\. ]] && [[ ! $ip =~ ^172\.1[7-9]\. ]] && [[ ! $ip =~ ^172\.2[0-9]\. ]] && [[ ! $ip =~ ^172\.3[0-1]\. ]]; then
                echo "  • $ip"
            fi
        done
        echo ""
    fi
fi

# Method 2: ip addr (detailed)
if command -v ip &> /dev/null; then
    PRIMARY_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$PRIMARY_IP" ]; then
        echo -e "${GREEN}Primary IP: ${PRIMARY_IP}${NC}"
        echo ""
    fi
fi

# Display API URL
if [ -n "$PRIMARY_IP" ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Backend API URL:${NC}"
    echo ""
    echo -e "  ${GREEN}http://${PRIMARY_IP}:8000${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Instructions
    echo -e "${YELLOW}To connect iOS app on macOS VM:${NC}"
    echo ""
    echo "1. Update iOS Constants.swift:"
    echo "   ios/SpeechMastery/Utilities/Constants.swift"
    echo ""
    echo "2. Change baseURL to:"
    echo -e "   ${GREEN}static let baseURL = \"http://${PRIMARY_IP}:8000\"${NC}"
    echo ""
    echo "3. Test connectivity from macOS VM:"
    echo -e "   ${GREEN}curl http://${PRIMARY_IP}:8000/health${NC}"
    echo ""

    # Test backend
    echo -e "${YELLOW}Testing backend endpoint...${NC}"
    if command -v curl &> /dev/null; then
        if curl -s --max-time 2 "http://${PRIMARY_IP}:8000/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Backend is accessible at http://${PRIMARY_IP}:8000${NC}"
        else
            echo -e "${YELLOW}⚠ Cannot reach backend at http://${PRIMARY_IP}:8000${NC}"
            echo "  Make sure:"
            echo "  - Backend is running: docker-compose up -d"
            echo "  - Firewall allows port 8000: sudo ufw allow 8000"
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}⚠ Could not determine IP address${NC}"
    echo "  Try manually with: ip addr show | grep 'inet '"
    echo ""
fi

# Additional network info
echo -e "${YELLOW}Network Interfaces:${NC}"
if command -v ip &> /dev/null; then
    ip addr show | grep -E "^[0-9]+: " | awk '{print $2}' | sed 's/:$//' | while read iface; do
        IP=$(ip addr show "$iface" | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1)
        if [ -n "$IP" ]; then
            echo "  • $iface: $IP"
        fi
    done
elif command -v ifconfig &> /dev/null; then
    ifconfig | grep -E "^[a-z]" | awk '{print $1}' | sed 's/:$//' | while read iface; do
        IP=$(ifconfig "$iface" | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}')
        if [ -n "$IP" ]; then
            echo "  • $iface: $IP"
        fi
    done
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""
