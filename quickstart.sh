#!/bin/bash
# quickstart.sh - Starts all services (database, backend, frontend)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Intelligent Pipeline System - Starting"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if command -v docker &> /dev/null && (command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1); then
    echo -e "${GREEN}✓ Docker${NC}"
    USE_DOCKER=true
elif command -v psql &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL${NC}"
    USE_DOCKER=false
else
    echo -e "${RED}✗ Install Docker or PostgreSQL 15+${NC}"
    exit 1
fi

[ -x "$(command -v python3)" ] && echo -e "${GREEN}✓ Python 3${NC}" || exit 1
[ -x "$(command -v npm)" ] && echo -e "${GREEN}✓ Node.js${NC}" || exit 1

echo ""

# Start services
if [ "$USE_DOCKER" = true ]; then
    echo -e "${BLUE}Starting Docker services...${NC}"
    docker compose up -d
    echo -e "${GREEN}✓ PostgreSQL + FastAPI started${NC}"
    sleep 15
else
    echo -e "${BLUE}Setting up native PostgreSQL...${NC}"
    DB_NAME="pipeline_gis"
    DB_USER="postgres"
    createdb -U "$DB_USER" -h localhost "$DB_NAME" 2>/dev/null || true
    psql -U "$DB_USER" -h localhost "$DB_NAME" < database_schema.sql
    echo -e "${GREEN}✓ Database ready${NC}"
    
    echo -e "${BLUE}Starting FastAPI backend...${NC}"
    cd backend
    [ ! -d "venv" ] && python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
    uvicorn main:app --reload > /tmp/fastapi.log 2>&1 &
    cd ..
    echo -e "${GREEN}✓ Backend started${NC}"
    sleep 3
fi

# Setup frontend
echo ""
echo -e "${BLUE}Starting React frontend...${NC}"
cd frontend
[ ! -d "node_modules" ] && npm install -q
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create .env
if [ ! -f ".env" ]; then
    cat > .env << 'EOF'
VITE_MAPBOX_TOKEN=pk_your_mapbox_token_here
VITE_API_URL=http://localhost:8000
EOF
    echo -e "${YELLOW}⚠ Add Mapbox token to frontend/.env${NC}"
fi

npm run dev &
cd ..

echo ""
echo -e "${GREEN}✓ All services started!${NC}"
echo ""
echo -e "${BLUE}Access points:${NC}"
echo "  App:       http://localhost:5173"
echo "  API:       http://localhost:8000"
echo "  Docs:      http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Add Mapbox token to frontend/.env for the map to work${NC}"
echo ""
echo -e "${GREEN}Press Ctrl+C to stop${NC}"
echo ""

wait
