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
- Start PostgreSQL, pgAdmin, and UserService in Docker containers
- Configure the database with default credentials from .env

## Accessing Services

### API Access
- Swagger UI: http://localhost:5280/swagger
- Base API URL: http://localhost:5280

### Accessing PostgreSQL

Using pgAdmin

1. Open your browser and go to: http://localhost:5050
2. Login with:
   - Email: admin@example.com (or as configured in `.env`)
   - Password: admin (or as configured in `.env`)
3. Add a new server:
   - Name: UserService (or any name you prefer)
   - Connection tab:
     - Host: postgres
     - Port: 5432
     - Maintenance database: postgres
     - Username: postgres (or as configured in `.env`)
     - Password: postgres (or as configured in `.env`)

## Testing the API

### Creating a User

```bash
curl -X POST "http://localhost:5280/api/Users" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Password123!",
    "firstName": "Test",
    "lastName": "User",
    "role": 0
  }'
```

### Login to Get a Token

```bash
curl -X POST "http://localhost:5280/api/Auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Password123!"
  }'
```

## Stopping the Environment

```bash
# Navigate to the ci-cd directory
# Stop and remove all containers
docker-compose -f docker-compose-local.yml down

# To remove all data and start fresh
docker-compose -f docker-compose-local.yml down -v
```
