#!/bin/bash

# Path to the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Ensure docker compose is the latest command
DOCKER_COMPOSE_CMD=$(command -v docker-compose || command -v docker\ compose)

# Copy .env.example to .env if .env doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file from .env.example"
fi

# Stop any running containers and remove volumes
echo "Stopping any running containers..."
$DOCKER_COMPOSE_CMD down -v


# Start PostgreSQL first
echo "Starting RabbitMQ..."
$DOCKER_COMPOSE_CMD up -d postgres rabbitmq
# Start PostgreSQL first
echo "Starting PostgreSQL..."
$DOCKER_COMPOSE_CMD up -d postgres

# Wait for PostgreSQL to be ready with more verbose logging
echo "Waiting for PostgreSQL to be ready..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    # More robust pg_isready check
    if docker exec $(docker compose ps -q postgres) pg_isready -U postgres -d microservices 2>/dev/null; then
        echo "PostgreSQL is ready!"
        break
    fi
    
    echo "Waiting for PostgreSQL to be ready... (Attempt $((++attempt))/$max_attempts)"
    
    # Optional: Check container logs if it takes too long
    if [ $attempt -eq 10 ]; then
        echo "PostgreSQL startup taking longer than expected. Checking logs..."
        docker compose logs postgres
    fi
    
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "PostgreSQL failed to start in time. Please check logs:"
    docker compose logs postgres
    exit 1
fi

# Build and start services
echo "Building and starting services..."
$DOCKER_COMPOSE_CMD up -d --build userservice locationservice reviewservice

# Wait a bit for services to start
echo "Waiting for services to initialize..."
sleep 15

# Load port mappings from .env file
set -a
source .env
set +a

echo "All services have been started!"
echo ""
echo "Services are running at:"
echo "  UserService:     http://localhost:${USERSERVICE_HTTP_PORT}/swagger"
echo "  LocationService: http://localhost:${LOCATIONSERVICE_HTTP_PORT}/swagger"
echo "  ReviewService:   http://localhost:${REVIEWSERVICE_HTTP_PORT}/swagger"
echo ""
echo "RabbitMQ Management:"
echo "  RabbitMQ UI:     http://localhost:${RABBITMQ_MANAGEMENT_PORT}"
