#!/bin/bash

# Check if .env file exists, otherwise use .env.example
if [ ! -f .env ]; then
    echo "No .env file found. Creating from .env.example"
    cp .env.example .env
fi

# Run PostgreSQL and pgAdmin locally with Docker
docker-compose -f docker-compose-local.yml up -d postgres pgadmin

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
sleep 5

# Apply migrations
cd ../back/UserService
dotnet ef database update --project UserService.Infrastructure --startup-project UserService.API

# Run the application
cd UserService.API
dotnet run
