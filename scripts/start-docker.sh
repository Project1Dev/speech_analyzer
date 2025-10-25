#!/bin/bash

#
# Docker Startup Script
#
# Starts all Docker containers and displays service URLs.
#
# Usage: ./scripts/start-docker.sh
#

set -e

echo "Starting Speech Mastery Docker Services..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi

echo "Starting Docker Compose..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Services are starting:"
echo ""
echo "Backend API:"
echo "  URL: http://localhost:8000"
echo "  Health: http://localhost:8000/health"
echo "  Docs: http://localhost:8000/docs"
echo ""
echo "Database (PostgreSQL):"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: speech_mastery_db"
echo "  Username: speech_mastery"
echo "  Password: dev_password_change_in_production"
echo ""
echo "Cache (Redis):"
echo "  Host: localhost"
echo "  Port: 6379"
echo ""
echo "pgAdmin (Database UI):"
echo "  URL: http://localhost:5050"
echo "  Email: admin@example.com"
echo "  Password: admin"
echo ""

# TODO: Verify service health
# TODO: Run migrations
# TODO: Seed database with sample data
# TODO: Load AI models
