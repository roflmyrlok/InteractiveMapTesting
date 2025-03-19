#!/bin/bash

# Script to initialize the PostgreSQL database
# This will be executed when the PostgreSQL container starts for the first time

set -e

# Check if the database already exists
DB_EXISTS=$(psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='microservices'")

if [ "$DB_EXISTS" != "1" ]; then
    echo "Creating microservices database..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
        CREATE DATABASE microservices;
        GRANT ALL PRIVILEGES ON DATABASE microservices TO $POSTGRES_USER;
EOSQL
    echo "Database created successfully!"
else
    echo "Database 'microservices' already exists. Skipping creation."
fi
