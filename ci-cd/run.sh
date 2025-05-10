#!/bin/bash

# Path to the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Ensure docker compose is the latest command
DOCKER_COMPOSE_CMD=$(command -v docker-compose || command -v docker\ compose)

# Copy .env.example to .env if .env doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    
    # Generate a secure JWT key
    JWT_KEY=$(openssl rand -base64 32)
    sed -i "s/YourSuperSecretKey12345678901234567890/$JWT_KEY/g" .env
    
    echo "Created .env file with secure JWT key"
fi

# Stop any running containers and remove volumes
echo "Stopping any running containers..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml down

# Start PostgreSQL first
echo "Starting PostgreSQL..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml up -d postgres

# Wait for PostgreSQL to be ready with more verbose logging
echo "Waiting for PostgreSQL to be ready..."
attempt=0
max_attempts=30
while [ $attempt -lt $max_attempts ]; do
    # Fixed pg_isready check - use docker ps to get container ID first
    POSTGRES_CONTAINER_ID=$(docker ps | grep postgres | awk '{print $1}')
    
    if [ -n "$POSTGRES_CONTAINER_ID" ]; then
        if docker exec $POSTGRES_CONTAINER_ID pg_isready -U postgres -d microservices 2>/dev/null; then
            echo "PostgreSQL is ready!"
            break
        fi
    else
        echo "PostgreSQL container not found. Waiting..."
    fi
    
    echo "Waiting for PostgreSQL to be ready... (Attempt $((++attempt))/$max_attempts)"
    
    # Optional: Check container logs if it takes too long
    if [ $attempt -eq 10 ]; then
        echo "PostgreSQL startup taking longer than expected. Checking logs..."
        POSTGRES_CONTAINER_ID=$(docker ps | grep postgres | awk '{print $1}')
        if [ -n "$POSTGRES_CONTAINER_ID" ]; then
            docker logs $POSTGRES_CONTAINER_ID
        else
            echo "PostgreSQL container not found yet. Still waiting..."
        fi
    fi
    
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "PostgreSQL failed to start in time. Please check logs:"
    POSTGRES_CONTAINER_ID=$(docker ps | grep postgres | awk '{print $1}')
    if [ -n "$POSTGRES_CONTAINER_ID" ]; then
        docker logs $POSTGRES_CONTAINER_ID
    else
        echo "PostgreSQL container not found. Check docker-compose configuration."
    fi
    exit 1
fi

# Build and start services
echo "Building and starting services..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml up -d userservice locationservice reviewservice

# Start the nginx proxy after services are up
echo "Starting Nginx reverse proxy..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml up -d nginx

# Wait a bit for services to start
echo "Waiting for services to initialize..."
sleep 15

# Try to get the public IP or use domain name from env
DOMAIN_NAME=""
if [ -f .env ]; then
    source .env
    DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
else
    DOMAIN_NAME="localhost"
fi

# If domain name is not set, try to get public IP
if [ "$DOMAIN_NAME" = "localhost" ]; then
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "")
        if [ -n "$PUBLIC_IP" ]; then
            DOMAIN_NAME=$PUBLIC_IP
        fi
    fi

    # If curl failed or returned empty, try using hostname
    if [ "$DOMAIN_NAME" = "localhost" ]; then
        HOSTNAME_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
        if [ -n "$HOSTNAME_IP" ]; then
            DOMAIN_NAME=$HOSTNAME_IP
        fi
    fi
fi

echo "All services have been started!"
echo ""
echo "Services are running at:"
echo "  API Gateway: http://$DOMAIN_NAME"
echo "  Swagger UI:"
echo "    - User Service: http://$DOMAIN_NAME/swagger/user"
echo "    - Location Service: http://$DOMAIN_NAME/swagger/location"
echo "    - Review Service: http://$DOMAIN_NAME/swagger/review"
echo ""
echo "Your services are now accessible through a single endpoint!"
