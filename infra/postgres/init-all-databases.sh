#!/bin/bash
set -e

# This script runs after PostgreSQL is initialized
# It creates separate databases and runs initialization scripts for each
# Runs as postgres superuser (default in docker-entrypoint-initdb.d)

POSTGRES_USER="${POSTGRES_USER:-postgres}"

echo "Creating separate databases..."

# Create databases (as postgres superuser, which is the default user in docker-entrypoint-initdb.d)
psql -v ON_ERROR_STOP=1 <<-EOSQL
    CREATE DATABASE restaurant_db;
    CREATE DATABASE driver_db;
    CREATE DATABASE orders_db;
    CREATE DATABASE notification_db;
    
    -- Grant privileges to the app user
    GRANT ALL PRIVILEGES ON DATABASE restaurant_db TO "$POSTGRES_USER";
    GRANT ALL PRIVILEGES ON DATABASE driver_db TO "$POSTGRES_USER";
    GRANT ALL PRIVILEGES ON DATABASE orders_db TO "$POSTGRES_USER";
    GRANT ALL PRIVILEGES ON DATABASE notification_db TO "$POSTGRES_USER";
EOSQL

echo "Initializing restaurant_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname restaurant_db < /docker-entrypoint-initdb.d/init-restaurant.sql

echo "Initializing driver_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname driver_db < /docker-entrypoint-initdb.d/init-driver.sql

echo "Initializing orders_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname orders_db < /docker-entrypoint-initdb.d/init-order.sql

echo "Initializing notification_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname notification_db < /docker-entrypoint-initdb.d/init-notification.sql

echo "All databases initialized successfully!"
