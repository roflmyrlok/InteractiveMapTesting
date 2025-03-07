#!/bin/bash

# Check if .env file exists, otherwise use .env.example
if [ ! -f .env ]; then
    echo "No .env file found. Creating from .env.example"
    cp .env.example .env
fi

# Run PostgreSQL, pgAdmin, and UserService with Docker
docker-compose -f docker-compose-local.yml up -d
