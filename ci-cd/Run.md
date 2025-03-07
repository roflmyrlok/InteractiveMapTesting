# User Service - Local Development Setup

## Setup Instructions

```bash
cd ci-cd

cp .env.example .env

chmod +x run-local.sh

./run-local.sh
```

This script will:
- Create a `.env` file from `.env.example` if one doesn't exist
- Start PostgreSQL and pgAdmin in Docker containers
- Configure the database with default credentials from .env

```bash
cd ../back/UserService

dotnet ef database update --project UserService.Infrastructure --startup-project UserService.API
```

```bash
# Navigate to the API project
cd UserService.API

# Run the application
dotnet run
```

http://localhost:5280
http://localhost:5280/swagger

## Accessing PostgreSQL

Using pgAdmin

1. Open your browser and go to: http://localhost:5050
2. Login with:
   - Email: admin@example.com (or as configured in `.env`)
   - Password: admin (or as configured in `.env`)
3. Add a new server:
   - Name: UserService (or any name you prefer)
   - Connection tab:
     - Host: postgres (or localhost if accessing outside Docker)
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
cd path/to/ci-cd

# Stop the containers
docker-compose -f docker-compose-local.yml down
```

To remove all data and start fresh:
```bash
docker-compose -f docker-compose-local.yml down -v
```
