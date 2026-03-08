# API Documentation

Complete reference for Intelligent Pipeline System REST API endpoints.

Base URL: `http://localhost:8000/api`

## Health & Status

### GET /health
Check API health status.

**Response**:
```json
{
  "status": "healthy",
  "service": "pipeline-api"
}
```

**HTTP Status**: 200 OK

---

## Pipeline Systems

### GET /pipelines
List all pipeline systems with metadata.

**Query Parameters**:
- `operator` (optional): Filter by operator name (substring match)

**Example**:
```bash
GET /api/pipelines
GET /api/pipelines?operator=Energy
```

**Response**:
```json
[
  {
    "id": 1,
    "name": "Midstream Crude Network",
    "operator_name": "Energy Transport Corp",
    "product": "Crude Oil",
    "region": "Permian Basin",
    "route_count": 2,
    "bbox": {
      "min_lon": -102.0779,
      "min_lat": 29.7604,
      "max_lon": -95.3698,
      "max_lat": 31.9973
    },
    "created_at": "2024-01-15T10:30:00"
  }
]
```

**Status**: 200 OK

---

## Pipeline Routes

### GET /pipelines/{route_id}
Get a single route with full GeoJSON geometry and properties.

**Path Parameters**:
- `route_id` (required, integer): Route ID

**Example**:
```bash
GET /api/pipelines/1
```

**Response** (GeoJSON Feature):
```json
{
  "type": "Feature",
  "id": 1,
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [-102.0779, 31.9973],
      [-101.8, 31.95],
      [-95.3698, 29.7604]
    ]
  },
  "properties": {
    "id": 1,
    "system_id": 1,
    "name": "Permian Main Trunk",
    "from_measure": 0,
    "to_measure": 380,
    "diameter_inches": 16,
    "material": "Steel",
    "grade": "API 5L X52",
    "length_miles": 350
  },
  "bbox": {
    "min_lon": -102.0779,
    "min_lat": 29.7604,
    "max_lon": -95.3698,
    "max_lat": 31.9973
  }
}
```

**Status**: 200 OK

**Error Responses**:
- 404: Route not found

---

## Pipe Segments

### GET /pipelines/{route_id}/segments
Get all pipe segments for a route as GeoJSON FeatureCollection.

**Path Parameters**:
- `route_id` (required, integer): Route ID

**Example**:
```bash
GET /api/pipelines/1/segments
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "Point",
        "coordinates": [-101.5, 31.95]
      },
      "properties": {
        "id": 1,
        "route_id": 1,
        "from_measure": 0,
        "to_measure": 50,
        "diameter_inches": 16,
        "wall_thickness_inches": 0.312,
        "material": "Steel",
        "grade": "API 5L X52",
        "coating": "Fusion Bonded Epoxy",
        "joint_type": "ERW",
        "installation_year": 2005,
        "operating_pressure_psi": 1200
      }
    }
  ]
}
```

**Status**: 200 OK

---

## Stations

### GET /pipelines/{route_id}/stations
Get all stations on a route as GeoJSON FeatureCollection.

**Path Parameters**:
- `route_id` (required, integer): Route ID

**Example**:
```bash
GET /api/pipelines/1/stations
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "Point",
        "coordinates": [-102.0779, 31.9973]
      },
      "properties": {
        "id": 1,
        "name": "Midland Pump Station",
        "station_type": "pump",
        "measure": 0,
        "capacity_units": "bhp",
        "capacity_value": 3500,
        "operating_pressure_psi": 1250
      }
    },
    {
      "type": "Feature",
      "id": 2,
      "geometry": {
        "type": "Point",
        "coordinates": [-95.3698, 29.7604]
      },
      "properties": {
        "id": 5,
        "name": "Houston Terminal",
        "station_type": "delivery",
        "measure": 380,
        "capacity_units": "bbl/day",
        "capacity_value": 5000,
        "operating_pressure_psi": 150
      }
    }
  ]
}
```

**Status**: 200 OK

---

## Valves

### GET /pipelines/{route_id}/valves
Get all valves on a route as GeoJSON FeatureCollection.

**Path Parameters**:
- `route_id` (required, integer): Route ID

**Query Parameters**:
- `valve_type` (optional): Filter by type (isolation, block, check, relief, regulator)

**Example**:
```bash
GET /api/pipelines/1/valves
GET /api/pipelines/1/valves?valve_type=block
GET /api/pipelines/1/valves?valve_type=isolation
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "Point",
        "coordinates": [-102.0779, 31.9973]
      },
      "properties": {
        "id": 1,
        "name": "MP0-Block Valve",
        "valve_type": "block",
        "normal_position": "open",
        "measure": 0,
        "size_inches": 16,
        "rating_psi": 1500
      }
    },
    {
      "type": "Feature",
      "id": 9,
      "geometry": {
        "type": "Point",
        "coordinates": [-97.0, 32.55]
      },
      "properties": {
        "id": 8,
        "name": "MP300-Relief Valve",
        "valve_type": "relief",
        "normal_position": "closed",
        "measure": 300,
        "size_inches": 12,
        "rating_psi": 1500
      }
    }
  ]
}
```

**Status**: 200 OK

**Query Filtering**:
- `?valve_type=block` returns only block valves
- `?valve_type=check` returns only check valves
- Case-insensitive matching

---

## Inline Devices

### GET /pipelines/{route_id}/devices
Get all inline devices on a route as GeoJSON FeatureCollection.

**Path Parameters**:
- `route_id` (required, integer): Route ID

**Query Parameters**:
- `device_type` (optional): Filter by type (meter, scraper_trap, separator, heater)

**Example**:
```bash
GET /api/pipelines/1/devices
GET /api/pipelines/1/devices?device_type=meter
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "Point",
        "coordinates": [-102.0779, 31.9973]
      },
      "properties": {
        "id": 1,
        "name": "Midland Flow Meter",
        "device_type": "meter",
        "measure": 2,
        "capacity_units": "bbl/day",
        "capacity_value": 45000
      }
    }
  ]
}
```

**Status**: 200 OK

---

## Spatial Queries

### GET /routes-near-point
Find all routes within a specified distance from a point.

**Query Parameters**:
- `longitude` (required, float): Point longitude (-180 to 180)
- `latitude` (required, float): Point latitude (-90 to 90)
- `distance_miles` (optional, float): Search radius in miles (default: 10)

**Example**:
```bash
GET /api/routes-near-point?longitude=-96.5&latitude=32&distance_miles=50
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "LineString",
        "coordinates": [[-102, 32], [-95, 30]]
      },
      "properties": {
        "id": 1,
        "name": "Permian Main Trunk",
        "system_id": 1
      }
    }
  ]
}
```

**Status**: 200 OK

**Notes**:
- Uses spheroidal distance (Earth model) for accuracy
- Distance conversion: 1 degree ≈ 69 miles
- Results use spatial index (GIST) for performance

---

### GET /routes-in-bounds
Find all routes intersecting a bounding box.

**Query Parameters**:
- `min_lon` (required, float): Minimum longitude
- `min_lat` (required, float): Minimum latitude
- `max_lon` (required, float): Maximum longitude
- `max_lat` (required, float): Maximum latitude

**Example**:
```bash
GET /api/routes-in-bounds?min_lon=-102&min_lat=29&max_lon=-95&max_lat=33
```

**Response** (GeoJSON FeatureCollection):
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "geometry": {
        "type": "LineString",
        "coordinates": [[-102.0779, 31.9973], [-95.3698, 29.7604]]
      },
      "properties": {
        "id": 1,
        "name": "Permian Main Trunk",
        "system_id": 1
      }
    }
  ]
}
```

**Status**: 200 OK

**Notes**:
- Bounds order: min must be less than max
- Uses ST_Intersects spatial operator
- Efficiently returns only routes within bounds

---

## Error Responses

### 404: Not Found
```json
{
  "detail": "Route not found"
}
```

### 422: Validation Error
```json
{
  "detail": [
    {
      "loc": ["query", "longitude"],
      "msg": "Field required",
      "type": "missing"
    }
  ]
}
```

### 500: Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## Data Types

### Measure (Milepost System)
- Type: Numeric(10, 2)
- Unit: Miles (or equivalent)
- Represents location along a route from start (0) to end
- Example: 45.5 = 45.5 miles from start of route

### Pressure
- Type: Integer
- Unit: PSI (Pounds per Square Inch)
- Example: 1200 PSI

### Diameter
- Type: Numeric
- Unit: Inches
- Example: 16 inches

### Coordinates
- Type: WGS84 (EPSG:4326)
- Format: [longitude, latitude]
- Example: [-96.5, 32.0]

---

## Pagination

Currently, endpoints return all results. For production, consider:
- Adding `?limit=50&offset=0` parameters
- Implementing cursor-based pagination
- Using PostGIS clustering for large datasets

---

## Performance Tips

1. **Use Type Filters** to limit results:
   ```bash
   GET /api/pipelines/1/valves?valve_type=block
   ```

2. **Use Spatial Queries** for large areas:
   ```bash
   GET /api/routes-in-bounds?min_lon=-100&min_lat=30&max_lon=-94&max_lat=34
   ```

3. **Cache Repeated Requests** in frontend:
   - Browser caching (add headers)
   - Redux/Context state caching
   - Service worker caching

---

## OpenAPI/Swagger

Interactive API documentation available at:
```
http://localhost:8000/docs
```

Provides:
- Endpoint explorer
- Request/response examples
- Schema validation
- Try-it-out functionality

---

## Rate Limiting

Not currently implemented. For production, add:
- FastAPI-Limiter
- Redis backend
- IP-based or token-based limits

---

## Authentication

Not currently implemented. For production, add:
- JWT bearer tokens
- API keys
- Role-based access control (RBAC)

---

## CORS

Default origins allowed (development):
- http://localhost:3000
- http://localhost:5173
- http://127.0.0.1:3000
- http://127.0.0.1:5173
- \* (all origins - change in production)

Update in `backend/main.py`:
```python
origins = [
    "https://api.example.com",
    "https://app.example.com",
]
```

---

Last updated: January 2024
Version: 1.0.0
