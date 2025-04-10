# Microservices Application

A scalable microservices architecture built with .NET 8, Entity Framework Core, and PostgreSQL. The application consists of three core services (User, Location, and Review) that communicate with each other through RESTful APIs and message queuing.

## Table of Contents

- [Architecture Overview](https://github.com/roflmyrlok/InteractiveMap/new/main?filename=README.md#architecture-overview)
- [Services](https://github.com/roflmyrlok/InteractiveMap/new/main?filename=README.md#services)
- [Project Structure](https://github.com/roflmyrlok/InteractiveMap/new/main?filename=README.md#project-structure)
- [Getting Started](https://github.com/roflmyrlok/InteractiveMap/new/main?filename=README.md#getting-started)
- [Other](https://github.com/roflmyrlok/InteractiveMap/new/main?filename=README.md#look-api-documentationmd-for-api-specs)

## Architecture Overview

The application uses a microservices architecture with the following components:

- **User Service**: Handles user registration, authentication, and management
- **Location Service**: Manages location data and location-based queries
- **Review Service**: Provides functionality for users to review locations
- **PostgreSQL**: Persistent storage for all services
- **RabbitMQ**: Message broker for inter-service communication

Each service follows a clean architecture pattern with the following layers:
- Domain: Core business logic and entities
- Application: Use cases and business rules
- Infrastructure: Data access, external services
- API: REST endpoints and controllers

## Services

### User Service
- User registration and authentication
- User profile management
- JWT token generation for secure API access
- Role-based access control

### Location Service
- Location CRUD operations
- Geospatial queries (nearby locations)
- Location details and properties management
- Location validation for other services

### Review Service
- Review CRUD operations
- Location rating system
- User-specific reviews
- Aggregate review metrics for locations

## Project Structure

```
├── backend/
│   ├── UserService/
│   │   ├── UserService.API
│   │   ├── UserService.Application
│   │   ├── UserService.Domain
│   │   ├── UserService.Infrastructure
│   │   └── UserService.Tests
│   ├── LocationService/
│   │   ├── LocationService.API
│   │   ├── LocationService.Application
│   │   ├── LocationService.Domain
│   │   ├── LocationService.Infrastructure
│   │   └── LocationService.Tests
│   └── ReviewService/
│       ├── ReviewService.API
│       ├── ReviewService.Application
│       ├── ReviewService.Domain
│       ├── ReviewService.Infrastructure
│       └── ReviewService.Tests
├── ci-cd/
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── run-local.sh
│   └── init-db.sh
└── README.md
```

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) and Docker Compose
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (for local development)
- [Git](https://git-scm.com/downloads)

### Running the Application localy

1. Clone the repository:
   ```bash
   git clone https://github.com/roflmyrlok/InteractiveMap
   cd InteractiveMap
   ```

2. Run the application using the provided script:
   ```bash
   cd ci-cd
   chmod +x run-local.sh
   chmod +x init-db.sh
   ./run-local.sh
   ```

This script will:
- Create a `.env` file from `.env.example` if one doesn't exist
- Start PostgreSQL, RabbitMQ, and all services in Docker containers
- Configure the database and apply migrations

### Accessing the Services

After successful startup, you can access the services at:

- User Service API: http://localhost:5280/swagger
- Location Service API: http://localhost:5282/swagger
- Review Service API: http://localhost:5284/swagger
- RabbitMQ Management UI: http://localhost:15672 (guest/guest)

- This depends on config and should be prompted after initialization

### Stopping the Application

To stop all services:

```bash
cd ci-cd
docker compose down
```

To remove all data and start fresh:

```bash
cd ci-cd
docker compose down -v
```


## Look API-Documentation.md for API specs

## Note on RabbitMQ

The application uses RabbitMQ for asynchronous communication between services:

 **Location Validation**:
   - When a user creates a review, the Review Service needs to validate that the location exists
   - Review Service publishes a `LocationValidationRequest` message to RabbitMQ
   - Location Service consumes the message, checks if the location exists
   - Location Service publishes a `LocationValidationResponse` message
   - Review Service consumes the response and proceeds accordingly
   - If Location Service / RabbitMQ / Review Service is not working some resources may not be created with server error in response, though other functionality should remain unafected
