@echo off
REM Quick start script for dolphin-mcp-pilot (Windows)

echo 🐬 Starting dolphin-mcp-pilot...
echo.

REM Check if .env file exists
if not exist .env (
    echo ❌ Error: .env file not found
    echo.
    echo Please follow these steps:
    echo   1. Copy the example config: copy .env.example .env
    echo   2. Edit .env and configure your DolphinScheduler connection
    echo   3. Run this script again
    echo.
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Docker is not running
    echo Please start Docker Desktop and try again
    exit /b 1
)

REM Start the service
echo 📦 Building and starting containers...
docker-compose up -d

REM Wait a moment for the service to start
timeout /t 2 /nobreak >nul

REM Check if container is running
docker ps | findstr dolphin-mcp-pilot >nul
if errorlevel 1 (
    echo.
    echo ⚠️  Container may not have started successfully
    echo Check logs with: docker-compose logs
    exit /b 1
)

echo.
echo ✅ dolphin-mcp-pilot is running!
echo.
echo 📍 Service URL: http://localhost:8001/mcp/
echo.
echo 📖 Next steps:
echo   - Check status: docker ps ^| findstr dolphin-mcp-pilot
echo   - View logs: docker-compose logs -f
echo   - Stop service: docker-compose down
echo.
