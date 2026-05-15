@echo off
REM Step 1: Stop and remove all running containers and delete volumes
echo Stopping and removing Docker containers, including volumes...
docker-compose down -v
if errorlevel 1 (
    echo Failed to stop Docker containers.
    exit /b 1
)

REM Step 2: Check if the build folder exists
if not exist "build\" (
    echo 'build' folder not found.
    if exist build.bat (
        echo Running build.bat to create it...
        call build.bat
        if errorlevel 1 (
            echo Failed to execute build.bat.
            exit /b 1
        )
    ) else (
        echo Attempting to run build.sh via bash if available...
        bash --version >nul 2>&1
        if errorlevel 1 (
            echo bash not found. Please provide build.bat or install Git Bash / WSL to run build.sh.
            exit /b 1
        )
        bash build.sh
        if errorlevel 1 (
            echo Failed to execute build.sh.
            exit /b 1
        )
    )
) else (
    echo 'build' folder exists, skipping build.
)

REM Step 3: Build and bring up containers with docker-compose
echo Building and starting Docker containers...
docker-compose up -d --build
if errorlevel 1 (
    echo Failed to start Docker containers.
    exit /b 1
)

echo Waiting for containers to initialize...
docker compose exec -T backend alembic upgrade head

echo Docker containers are up and running.
