#!/bin/bash

# Script to initialize the PostgreSQL database
# This will be executed when the PostgreSQL container starts for the first time

set -e

# Create the microservices database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    CREATE DATABASE microservices;
    GRANT ALL PRIVILEGES ON DATABASE microservices TO $POSTGRES_USER;
EOSQL

echo "Database created successfully!"
