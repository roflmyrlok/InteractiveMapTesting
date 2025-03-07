#!/bin/bash

# Ensure .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example"
    cp .env.example .env
fi

# Create a .env file if it doesn't exist
# This ensures we have default values for local development
if ! grep -q "JWT_SECRET_KEY" .env; then
    echo "Adding default JWT configuration to .env"
    echo "JWT_SECRET_KEY=YourSuperSecretKey12345678901234567890" >> .env
    echo "JWT_ISSUER=UserService" >> .env
    echo "JWT_AUDIENCE=UserServiceClient" >> .env
fi

# Pull the latest images and rebuild containers
docker-compose -f docker-compose-local.yml down
docker-compose -f docker-compose-local.yml pull
docker-compose -f docker-compose-local.yml up --build
