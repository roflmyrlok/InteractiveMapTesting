#!/bin/bash

# Path to the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Stop any running containers and remove volumes
echo "Stopping any running containers..."
docker compose down -v

# Start PostgreSQL first
echo "Starting PostgreSQL..."
docker compose up -d postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
attempt=0
max_attempts=30
until docker exec $(docker compose ps -q postgres) pg_isready -U postgres 2>/dev/null || [ $attempt -eq $max_attempts ]; do
    echo "Waiting for PostgreSQL to be ready... (Attempt $((++attempt))/$max_attempts)"
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "PostgreSQL failed to start in time. Please check logs with: docker compose logs postgres"
    exit 1
fi

echo "PostgreSQL is ready!"

# Build and start UserService
echo "Building and starting UserService..."
docker compose up -d --build userservice

# Build and start LocationService
echo "Building and starting LocationService..."
docker compose up -d --build locationservice

echo "Building and starting ReviewService..."
#docker compose up -d --build reviewservice

# Wait a bit for UserService to start
echo "Waiting for services to initialize..."
sleep 10

echo "All services have been started!"
echo ""
echo "Services are running at:"
echo "  UserService:     http://localhost:5280/swagger"
echo "  LocationService: http://localhost:5281/swagger"
echo "  LocationService: http://localhost:5282/swagger"

