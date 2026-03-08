@echo off
REM quickstart.bat - Quick start script for Intelligent Pipeline System (Windows)

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo Intelligent Pipeline System - Quick Start
echo ==========================================
echo.

REM Check prerequisites
echo Checking prerequisites...

REM Check PostgreSQL
where psql >nul 2>nul
if %errorlevel% neq 0 (
    echo PostgreSQL not found. Please install PostgreSQL 15+
    exit /b 1
)
echo [OK] PostgreSQL found

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python not found. Please install Python 3.9+
    exit /b 1
)
echo [OK] Python found

REM Check Node.js
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js/npm not found. Please install Node.js 16+
    exit /b 1
)
echo [OK] Node.js/npm found

echo.
echo Setting up database...

REM Create database
set DB_NAME=pipeline_gis
set DB_USER=postgres
set DB_HOST=localhost

REM Create database (ignore error if exists)
createdb -U %DB_USER% -h %DB_HOST% %DB_NAME% 2>nul

REM Load schema
psql -U %DB_USER% -h %DB_HOST% %DB_NAME% < database_schema.sql
echo [OK] Database and sample data loaded

echo.
echo Setting up backend...

cd backend

REM Create virtual environment
if not exist venv (
    python -m venv venv
    echo [OK] Virtual environment created
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install dependencies
pip install -q -r requirements.txt
echo [OK] Python dependencies installed

cd ..

echo.
echo Setting up frontend...

cd frontend

REM Install npm dependencies
call npm install --silent
echo [OK] Node.js dependencies installed

REM Check .env file
if not exist .env (
    echo Creating frontend .env...
    (
        echo VITE_MAPBOX_TOKEN=your_token_here
        echo VITE_API_URL=http://localhost:8000
    ) > .env
)

cd ..

echo.
echo ==========================================
echo Setup Complete!
echo ==========================================
echo.
echo Next steps:
echo.
echo 1. Start the backend:
echo    cd backend
echo    venv\Scripts\activate.bat
echo    uvicorn main:app --reload
echo.
echo 2. In a new command prompt, start the frontend:
echo    cd frontend
echo    npm run dev
echo.
echo 3. Open your browser to:
echo    http://localhost:5173
echo.
echo API Documentation:
echo    http://localhost:8000/docs
echo.
echo Important:
echo    Add your Mapbox token to frontend\.env
echo    Get one at https://account.mapbox.com/tokens/
echo.
