# Quick Verification Checklist

## Project Structure

Verify all files are created:

```bash
# From ips/ directory
ls -la

# Backend files
ls -la backend/
ls -la backend/routers/

# Frontend files
ls -la frontend/
ls -la frontend/src/
```

Expected file count: 30+ files

## Database Verification

### 1. Connect to PostgreSQL

```bash
psql -h localhost -U postgres -d pipeline_gis
```

### 2. Check Tables Created

```sql
-- List tables
\dt

-- Expected tables:
-- pipelines_systems
-- pipelines_routes
-- pipelines_segments
-- pipelines_stations
-- pipelines_valves
-- pipelines_inline_devices
```

### 3. Check Sample Data

```sql
SELECT 'Systems' as table_name, COUNT(*) as count FROM pipelines_systems
UNION ALL
SELECT 'Routes', COUNT(*) FROM pipelines_routes
UNION ALL
SELECT 'Segments', COUNT(*) FROM pipelines_segments
UNION ALL
SELECT 'Stations', COUNT(*) FROM pipelines_stations
UNION ALL
SELECT 'Valves', COUNT(*) FROM pipelines_valves
UNION ALL
SELECT 'Devices', COUNT(*) FROM pipelines_inline_devices;
```

Expected output:
```
   table_name   | count
----------------+-------
 Devices        |     4
 Routes         |     3
 Segments       |     8
 Stations       |     7
 Systems        |     2
 Valves         |    11
```

### 4. Verify PostGIS

```sql
SELECT PostGIS_Version();
SELECT ST_Distance(
  ST_GeomFromText('POINT(-102.0779 31.9973)', 4326),
  ST_GeomFromText('POINT(-95.3698 29.7604)', 4326)
) as distance_degrees;
```

### 5. Verify Spatial Indexes

```sql
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename LIKE 'pipelines_%' AND indexname LIKE '%geom%';
```

Expected: 4 GIST indexes (route, stations, valves, devices)

## Backend Verification

### 1. Python Environment

```bash
cd backend

# Verify virtual environment
python --version          # Should be 3.9+
pip --version

# Verify dependencies
pip list | grep -E "fastapi|sqlalchemy|asyncpg|geoalchemy"
```

### 2. Start Backend Server

```bash
# From backend/ directory
source venv/bin/activate
uvicorn main:app --reload
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

### 3. Test API Health

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status":"healthy","service":"pipeline-api"}
```

### 4. Test Pipeline Systems Endpoint

```bash
curl http://localhost:8000/api/pipelines | jq .
```

Expected: List of 2 systems with metadata

### 5. Test Route GeoJSON Endpoint

```bash
curl http://localhost:8000/api/pipelines/1 | jq .geometry.type
```

Expected output:
```
"LineString"
```

### 6. Test Feature Endpoints

```bash
# Stations
curl http://localhost:8000/api/pipelines/1/stations | jq '.features | length'

# Valves
curl http://localhost:8000/api/pipelines/1/valves | jq '.features | length'

# Devices
curl http://localhost:8000/api/pipelines/1/devices | jq '.features | length'
```

### 7. API Documentation

Visit: http://localhost:8000/docs

Should see Swagger UI with all endpoints

## Frontend Verification

### 1. Node.js Setup

```bash
cd frontend

# Verify Node.js
node --version    # Should be 16+
npm --version

# Verify dependencies
npm list react react-map-gl axios
```

### 2. Environment Configuration

```bash
# Check .env file exists
cat .env

# Should contain:
# VITE_MAPBOX_TOKEN=...
# VITE_API_URL=http://localhost:8000
```

### 3. Add Mapbox Token

If you haven't gotten a token:
1. Go to https://account.mapbox.com/tokens/
2. Click "Create a token"
3. Copy token
4. Edit `frontend/.env`:
   ```
   VITE_MAPBOX_TOKEN=pk_your_token_here
   ```

### 4. Build Frontend

```bash
npm run build
```

Expected output:
```
✓ built in XXs
```

### 5. Start Development Server

```bash
npm run dev
```

Expected output:
```
VITE v5.0.8  ready in XXX ms

➜  Local:   http://127.0.0.1:5173/
```

### 6. Open in Browser

Visit: http://localhost:5173

Verify:
- ✅ Page loads without errors
- ✅ Mapbox map displays
- ✅ Sidebar shows pipeline systems
- ✅ Console has no errors (F12)

## End-to-End Verification

### 1. Select a Pipeline Route

1. Click "Energy Transport Corp" > "Permian Main Trunk"
2. Verify:
   - ✅ Map zooms to route bounds
   - ✅ Route line (red) displays
   - ✅ Station circles show on map

### 2. Toggle Features

1. Click "Segments" toggle
2. Click "Valves" toggle
3. Verify:
   - ✅ Feature counts show
   - ✅ Layers appear/disappear on map

### 3. Click Features

1. Click a valve on the map
2. Verify:
   - ✅ Popup appears
   - ✅ Shows: name, type, measure, diameter, pressure, etc.

### 4. Check Browser Console

Press F12, check Console tab:
- ✅ No JavaScript errors
- ✅ API calls logged (network tab)

### 5. Test API Directly

```bash
# Get route with geometry
curl -s http://localhost:8000/api/pipelines/1 | jq '.properties | keys'

# Get stations as GeoJSON
curl -s http://localhost:8000/api/pipelines/1/stations | jq '.features[0]'

# Filter valves
curl -s 'http://localhost:8000/api/pipelines/1/valves?valve_type=block' | jq '.features | length'
```

## Sample Data Walkthrough

### System 1: Permian Main Trunk (Crude Oil)
- Operator: Energy Transport Corp
- Length: 350 miles
- Route: Midland, TX → Houston, TX
- Features:
  - 5 stations (pump, regulator, delivery)
  - 11 valves (block, isolation, check, relief)
  - 4 inline meters
  - 8 pipe segments

### System 2: Oklahoma to Kansas Gas
- Operator: GasFlow Inc
- Length: 120 miles
- Product: Natural Gas
- Features:
  - 2 stations (compressor, regulator)
  - 4 valves (block, isolation, check)

## Troubleshooting

### "Cannot connect to database"
```bash
# Check PostgreSQL running
psql --version
psql -h localhost -U postgres -d pipeline_gis -c "SELECT 1"
```

### "Module not found" errors
```bash
# Reinstall dependencies
pip install -r requirements.txt
npm install
```

### Map doesn't load
```bash
# Check Mapbox token
cat frontend/.env
# Verify token format (starts with pk_)
```

### API not responding
```bash
# Check backend running
curl -v http://localhost:8000/health

# Check database connection
cat backend/.env
# Verify DATABASE_URL format
```

### CORS errors
```bash
# Check backend CORS config
grep -n "origins.*=" backend/main.py
# Should include http://localhost:5173
```

## Performance Testing

### Database Query Performance

```bash
# Connect to database
psql pipeline_gis

-- Test spatial query (should use index)
EXPLAIN ANALYZE
SELECT * FROM pipelines_routes
WHERE ST_DWithin(geom, ST_Point(-96, 32, 4326), 0.1);

-- Should show GIST index usage
```

### API Response Time

```bash
# Time API call
time curl -s http://localhost:8000/api/pipelines/1 > /dev/null

# Should complete in <100ms
```

### Frontend Load Time

In browser DevTools (F12):
1. Network tab: Check load time
2. Performance tab: Record and analyze
3. Expected: Full load <2 seconds

## File Sizes

Verify reasonable file sizes:
```bash
# Backend
ls -lh backend/*.py        # Each <50KB
du -sh backend/            # Total ~500KB

# Frontend
ls -lh frontend/src/*.jsx  # Each <20KB
du -sh frontend/           # Total ~300KB (before node_modules)

# Database dump
ls -lh database_schema.sql # ~50KB
```

## Next Steps

1. ✅ Verify all checks pass
2. 📚 Read [README.md](README.md) for detailed documentation
3. 🚀 Read [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment
4. 🔧 Customize sample data in `database_schema.sql`
5. 🎨 Modify colors and styling in frontend
6. 📡 Add more endpoints as needed

## Support Resources

- **PostGIS Docs**: https://postgis.net/documentation/
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **React Docs**: https://react.dev/
- **Mapbox GL JS**: https://docs.mapbox.com/mapbox-gl-js/
- **SQLAlchemy**: https://docs.sqlalchemy.org/

---

**All checks passing? 🎉 You're ready to start developing!**

For issues, check the logs and error messages. Most problems are:
1. Missing Mapbox token
2. Database not running
3. Backend port 8000 in use
4. Frontend port 5173 in use

Use `lsof -i :8000` (macOS/Linux) or `netstat -ano | findstr :8000` (Windows) to check port usage.
