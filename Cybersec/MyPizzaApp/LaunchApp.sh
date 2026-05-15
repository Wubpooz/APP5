#!/bin/bash

# Step 1: Stop and remove all running containers and delete volumes
echo "Stopping and removing Docker containers, including volumes..."
docker-compose down -v
if [[ $? -ne 0 ]]; then
    echo "Failed to stop Docker containers."
    exit 1
fi

# Step 2: Check if the build folder exists
if [[ ! -d "./build" ]]; then
    echo "'build' folder not found. Running build.sh to create it..."
    ./build.sh
    if [[ $? -ne 0 ]]; then
        echo "Failed to execute build.sh."
        exit 1
    fi
else
    echo "'build' folder exists, skipping build.sh."
fi

# Step 3: Build and bring up containers with docker-compose
echo "Building and starting Docker containers..."
docker-compose up -d --build
if [[ $? -ne 0 ]]; then
    echo "Failed to start Docker containers."
    exit 1
fi

echo "Waiting for containers to initialize..."
DB_READY=0
for i in {1..30}; do
    if docker compose exec -T db sh -c "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB" >/dev/null 2>&1; then
        DB_READY=1
        break
    fi
    sleep 2
done

if [[ $DB_READY -ne 1 ]]; then
    echo "Database did not become ready in time."
    exit 1
fi

docker compose exec -T backend alembic upgrade head
if [[ $? -ne 0 ]]; then
    echo "Failed to run database migrations."
    exit 1
fi

echo "Docker containers are up and running."
