# Intelligent Pipeline System Web App

A complete, production-ready GIS web application for pipeline infrastructure management built with FastAPI, React, PostGIS, and Mapbox GL JS.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│   React Frontend (Mapbox GL JS)         │
│   • Interactive map visualization       │
│   • Pipeline list sidebar               │
│   • Feature selection & details         │
└────────────────┬────────────────────────┘
                 │ HTTP/REST
┌────────────────▼────────────────────────┐
│   FastAPI Backend                       │
│   • GeoJSON endpoints                   │
│   • Spatial queries (ST_DWithin, etc.)  │
│   • Async/await with asyncpg           │
└────────────────┬────────────────────────┘
                 │ SQL
┌────────────────▼────────────────────────┐
│   PostgreSQL + PostGIS                  │
│   • PODS-inspired schema                │
│   • Spatial indexes (GIST)              │
│   • Sample Permian Basin data           │
└─────────────────────────────────────────┘
```

## Features

### Backend (FastAPI + PostGIS)
- ✅ Complete PODS-inspired schema (systems, routes, segments, stations, valves, devices)
- ✅ GeoJSON responses for Mapbox compatibility
- ✅ Async database operations with asyncpg
- ✅ Spatial queries: ST_DWithin, ST_Intersects, ST_Extent
- ✅ Proper spatial indexes (GIST) for performance
- ✅ CORS enabled for frontend development
- ✅ Comprehensive error handling
- ✅ OpenAPI documentation at `/docs`

### Frontend (React + Mapbox GL JS)
- ✅ Interactive Mapbox map centered on US
- ✅ Sidebar with hierarchical pipeline/route list
- ✅ Feature selection with popup details
- ✅ Toggle layers: segments, stations, valves, devices
- ✅ Color-coded layers by feature type
- ✅ Responsive Tailwind CSS styling
- ✅ Loading states and error handling
- ✅ Fly-to bounds on route selection

### Database (PostgreSQL + PostGIS)
- ✅ Sample data: 2 pipeline systems, 3 routes, 25+ infrastructure features
- ✅ Realistic coordinates (Permian Basin, Mid-Continent US)
- ✅ Complete attribute data (diameter, pressure, valve types, etc.)
- ✅ Spatial indexes for query performance
- ✅ Foreign key relationships

## Project Structure

```
ips/
├── database_schema.sql          # PostgreSQL + PostGIS DDL + sample data
│
├── backend/                     # FastAPI application
│   ├── main.py                  # FastAPI app and routes
│   ├── models.py                # SQLAlchemy ORM models
│   ├── schemas.py               # Pydantic request/response schemas
│   ├── database.py              # Database configuration
│   ├── requirements.txt          # Python dependencies
│   ├── .env                      # Environment variables
│   └── routers/
│       └── pipelines.py          # Pipeline API endpoints
│
└── frontend/                    # React application
    ├── package.json             # Node.js dependencies
    ├── vite.config.js           # Vite configuration
    ├── tailwind.config.js       # Tailwind CSS config
    ├── postcss.config.js        # PostCSS config
    ├── index.html               # HTML entry point
    ├── .env                      # Frontend environment variables
    └── src/
        ├── main.jsx             # React entry point
        ├── App.jsx              # Main app component
        ├── Map.jsx              # Mapbox map component
        ├── PipelineList.jsx     # Sidebar component
        ├── api.js               # API client
        └── index.css            # Tailwind + custom styles
```

## Prerequisites

- **PostgreSQL 15+** with PostGIS 3.4+
- **Python 3.9+** with pip
- **Node.js 16+** and npm
- **Mapbox account** (free tier available at https://mapbox.com)

## Installation & Setup

### 1. Database Setup

```bash
# Create PostgreSQL database
createdb pipeline_gis

# Load schema and sample data
psql pipeline_gis < database_schema.sql

# Verify (optional)
psql pipeline_gis -c "SELECT COUNT(*) as systems FROM pipelines_systems;"
```

You should see:
```
 systems
---------
       2
(1 row)
```

### 2. Backend Setup

```bash
cd backend

# Create Python virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure database connection (edit .env if needed)
# Default: postgresql+asyncpg://postgres:password@localhost:5432/pipeline_gis
cat .env

# Run the server
uvicorn main:app --reload

# Server runs at http://localhost:8000
# API docs available at http://localhost:8000/docs
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Configure Mapbox token
# Edit .env and add your Mapbox token:
# VITE_MAPBOX_TOKEN=your_actual_token_here
# Get one at https://account.mapbox.com/tokens/

# Start development server
npm run dev

# Frontend runs at http://localhost:5173
```

### 4. Open Application

Open browser to **http://localhost:5173**

## Usage

### Selecting a Pipeline
1. **Left sidebar**: Browse pipeline systems and routes
2. **Click a route**: View route geometry on map
3. **Map zooms** to route bounds automatically

### Visualizing Features
- **Toggle buttons** in top panel:
  - ✓ **Segments**: Pipe section attributes
  - ✓ **Stations**: Compressor, pump, regulator stations
  - ✓ **Valves**: Isolation, block, check, relief valves
  - **Devices**: Flow meters, scraper traps, etc.

### Feature Details
- **Click any feature** on map (station, valve, device)
- **Popup shows**:
  - Name, type
  - Location (measure along route)
  - Technical specs (diameter, pressure, capacity)
  - Material/grade, status

## API Endpoints

### Pipeline Systems
```
GET /api/pipelines
  Query: operator (optional)
  Returns: List of systems with metadata and bbox
```

### Route Data (GeoJSON)
```
GET /api/pipelines/{route_id}
  Returns: GeoJSON Feature with LineString geometry

GET /api/pipelines/{route_id}/segments
  Returns: GeoJSON FeatureCollection of segments

GET /api/pipelines/{route_id}/stations
  Returns: GeoJSON FeatureCollection of stations

GET /api/pipelines/{route_id}/valves
  Query: valve_type (optional)
  Returns: GeoJSON FeatureCollection of valves

GET /api/pipelines/{route_id}/devices
  Query: device_type (optional)
  Returns: GeoJSON FeatureCollection of devices
```

### Spatial Queries
```
GET /api/routes-near-point
  Query: longitude, latitude, distance_miles (optional)
  Returns: Routes within distance

GET /api/routes-in-bounds
  Query: min_lon, min_lat, max_lon, max_lat
  Returns: Routes intersecting bounding box
```

## Data Schema

### Pipeline Systems
- **Operator, name, product type** (Crude Oil, Natural Gas, etc.)
- **Region information**

### Routes
- **LINESTRING geometry** (WGS84 EPSG:4326 for Mapbox)
- **From/to measures** (milepost system)
- **Diameter, material, grade, length**

### Segments
- **Per-segment attributes**: diameter, wall thickness, coating, joint type
- **Installation year, operating pressure**

### Stations
- **Type**: Compressor, pump, regulator, reception, delivery
- **Capacity** (BHP, GPM, SCF/day)
- **Operating pressure**

### Valves
- **Type**: Isolation, block, check, relief, regulator
- **Size, rating, normal position**

### Inline Devices
- **Type**: Meter, scraper trap, separator, heater
- **Capacity by unit type**

## Sample Data

The database includes:
- **2 Pipeline Systems**:
  - Energy Transport Corp (Crude Oil) - Permian Basin
  - GasFlow Inc (Natural Gas) - Mid-Continent
- **3 Routes**:
  - Permian Main Trunk: 380 miles, 16" crude pipeline
  - West Texas Branch: 55 miles, 12" crude branch
  - Oklahoma to Kansas Gas: 120 miles, 30" natural gas
- **25+ Infrastructure Features**:
  - 5 pump/compressor/regulator stations
  - 11 valves (block, isolation, check, relief)
  - 4 inline meters
  - Full measure-based positioning (**milepost system**)

## Key Technical Details

### Spatial Queries (Performance Optimized)
```python
# ST_DWithin for radius searches
ST_DWithin(geom, point, distance, true)  # Uses spheroid (Earth model)

# ST_Intersects for bounding box
ST_Intersects(geom, envelope)

# ST_Extent for aggregate bounds
ST_Extent(geom)
```

### Indexing
- **GIST indexes** on all geometry columns (routes, stations, valves, devices)
- **Hash indexes** on foreign keys for join performance
- **Query planner** leverages indexes automatically

### Async Architecture
- **AsyncSession** with SQLAlchemy
- **asyncpg** for non-blocking PostgreSQL  
- **NullPool** recommended for multiple workers
- Connection pooling managed per request

### GeoJSON Format
All geometry responses follow RFC 7946 GeoJSON spec:
```json
{
  "type": "Feature",
  "geometry": {
    "type": "LineString|Point",
    "coordinates": [lon, lat]
  },
  "properties": { /* feature attributes */ }
}
```

## Environment Variables

### Backend (.env)
```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/pipeline_gis
SQL_ECHO=false                  # Enable SQL logging
API_HOST=0.0.0.0
API_PORT=8000
API_RELOAD=true                 # Auto-reload on code changes
```

### Frontend (.env)
```bash
VITE_MAPBOX_TOKEN=pk_...        # Get from Mapbox dashboard
VITE_API_URL=http://localhost:8000
```

## Troubleshooting

### Database Connection Refused
```bash
# Check PostgreSQL is running
psql --version

# Verify connection
psql -h localhost -U postgres -d pipeline_gis -c "SELECT version();"

# Check PostGIS installed
psql -d pipeline_gis -c "SELECT PostGIS_Version();"
```

### "No routes available" in sidebar
- Verify `database_schema.sql` was loaded
- Check route count: `psql pipeline_gis -c "SELECT COUNT(*) FROM pipelines_routes;"`

### Map not rendering
- Verify **Mapbox token** is in `frontend/.env`
- Check browser console for errors
- Ensure backend is running at `http://localhost:8000`

### CORS errors in browser
- Backend auto-allows localhost:3000 and localhost:5173
- For production, edit `origins` list in `backend/main.py`

## Production Deployment

### Backend (Gunicorn + Uvicorn)
```bash
pip install gunicorn
gunicorn main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000
```

### Frontend (Build & Serve)
```bash
npm run build                   # Creates dist/
# Serve dist/ with Nginx/Apache/S3
```

### Database (Managed PostgreSQL)
- Use AWS RDS, Google Cloud SQL, or Heroku PostgreSQL
- Ensure PostGIS extension enabled
- Run `database_schema.sql` on remote instance

## Performance Considerations

1. **Spatial Indexes**: GIST indexes on all geometry columns
2. **Query Optimization**: Use ST_DWithin with spheroid=true for accurate distances
3. **Caching**: Add Redis for frequently accessed routes (not included)
4. **Async I/O**: FastAPI handles concurrent requests efficiently
5. **Frontend Optimization**: Mapbox dynamically loads tiles; layers added/removed on toggle

## Additional Resources

- **PostGIS Docs**: https://postgis.net/documentation/
- **Mapbox GL JS**: https://docs.mapbox.com/mapbox-gl-js/
- **FastAPI**: https://fastapi.tiangolo.com/
- **SQLAlchemy**: https://docs.sqlalchemy.org/
- **GeoAlchemy2**: https://geoalchemy-2.readthedocs.io/

## License

MIT License - Modify and distribute freely

---

**Built with ❤️ using FastAPI, React, PostGIS, and Mapbox**
