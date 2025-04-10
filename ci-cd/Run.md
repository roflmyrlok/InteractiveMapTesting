# User Service - Local Development Setup

## Setup Instructions

```bash
cd ci-cd

# Copy .env example if .env doesn't exist
cp .env.example .env

# Make run script executable
chmod +x run-local.sh

# Start all services (PostgreSQL, pgAdmin, UserService)
./run-local.sh
```

This script will:

- Create a `.env` file from `.env.example` if one doesn't exist
- Start PostgreSQL, and Services in Docker containers
- Configure the database with credentials from .env

## Accessing Services

### API Access

- UserService API URL: http://localhost:5280
- LocationService API URL: http://localhost:5281
- ReviewService URL: http://localhost:5282

## Stopping the Environment

```bash
docker-compose -f docker-compose-local.yml down

# To remove all data and start fresh
docker-compose -f docker-compose-local.yml down -v
```
