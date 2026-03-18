"""
FastAPI routers for pipeline endpoints.
Returns GeoJSON-formatted geometry for Mapbox compatibility.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, func
from geoalchemy2 import functions as geofunc
from geoalchemy2.elements import WKBElement
import json

from database import get_db
from models import (
    PipelineSystem, PipelineRoute, PipelineSegment,
    PipelineStation, PipelineValve, PipelineInlineDevice
)
import schemas

router = APIRouter(prefix="/api", tags=["pipelines"])


# ============================================================================
# Utility Functions for GeoJSON Conversion
# ============================================================================

def geometry_to_geojson(geom_obj):
    """Convert PostGIS geometry to GeoJSON dict."""
    if geom_obj is None:
        return None
    
    try:
        # Handle WKBElement from GeoAlchemy2
        if isinstance(geom_obj, WKBElement):
            # WKBElement has comparator/type attributes we can use
            # Try to get the raw geo_interface if available
            if hasattr(geom_obj, 'expr'):
                # This is a column expression, not actual geometry
                return None
            # Try to parse the __geo_interface__ attribute
            if hasattr(geom_obj, '__geo_interface__'):
                return dict(geom_obj.__geo_interface__)
        
        # Handle Shapely geometry objects or anything with __geo_interface__
        if hasattr(geom_obj, '__geo_interface__'):
            return dict(geom_obj.__geo_interface__)
        
        # If it's already a dict, return it
        if isinstance(geom_obj, dict):
            return geom_obj
        
        return None
    except Exception as e:
        print(f"Error converting geometry to GeoJSON: {type(geom_obj)}: {e}")
        return None


async def get_route_bbox(session: AsyncSession, route_id: int) -> Optional[schemas.BoundingBox]:
    """Calculate bounding box for a route."""
    stmt = select(
        func.ST_XMin(PipelineRoute.geom).label('min_lon'),
        func.ST_YMin(PipelineRoute.geom).label('min_lat'),
        func.ST_XMax(PipelineRoute.geom).label('max_lon'),
        func.ST_YMax(PipelineRoute.geom).label('max_lat'),
    ).where(PipelineRoute.id == route_id)
    
    result = await session.execute(stmt)
    row = result.one_or_none()
    
    if row and row.min_lon:
        return schemas.BoundingBox(
            min_lon=float(row.min_lon),
            min_lat=float(row.min_lat),
            max_lon=float(row.max_lon),
            max_lat=float(row.max_lat),
        )
    return None


# ============================================================================
# Pipeline Systems Endpoints
# ============================================================================

@router.get("/systems-with-routes")
async def list_systems_with_routes(
    session: AsyncSession = Depends(get_db),
    operator: Optional[str] = Query(None, description="Filter by operator name")
):
    """
    List all pipeline systems WITH their routes nested.
    Used by frontend to populate sidebar with expandable routes.
    
    Returns: List of systems, each with a 'routes' array.
    """
    stmt = select(PipelineSystem)
    
    if operator:
        stmt = stmt.where(PipelineSystem.operator_name.ilike(f"%{operator}%"))
    
    result = await session.execute(stmt)
    systems = result.scalars().all()
    
    response = []
    for system in systems:
        # Get all routes for this system
        routes_stmt = select(PipelineRoute).where(
            PipelineRoute.system_id == system.id
        ).order_by(PipelineRoute.name)
        
        routes_result = await session.execute(routes_stmt)
        routes = routes_result.scalars().all()
        
        # Get bbox of all routes in system
        bbox_stmt = select(
            func.ST_XMin(func.ST_Extent(PipelineRoute.geom)).label('min_lon'),
            func.ST_YMin(func.ST_Extent(PipelineRoute.geom)).label('min_lat'),
            func.ST_XMax(func.ST_Extent(PipelineRoute.geom)).label('max_lon'),
            func.ST_YMax(func.ST_Extent(PipelineRoute.geom)).label('max_lat'),
        ).where(PipelineRoute.system_id == system.id)
        
        bbox_result = await session.execute(bbox_stmt)
        bbox_row = bbox_result.one_or_none()
        
        bbox = None
        if bbox_row and bbox_row.min_lon:
            bbox = schemas.BoundingBox(
                min_lon=float(bbox_row.min_lon),
                min_lat=float(bbox_row.min_lat),
                max_lon=float(bbox_row.max_lon),
                max_lat=float(bbox_row.max_lat),
            )
        
        # Build routes list
        routes_list = []
        for route in routes:
            routes_list.append({
                "id": route.id,
                "name": route.name,
                "from_measure": float(route.from_measure) if route.from_measure else 0,
                "to_measure": float(route.to_measure) if route.to_measure else None,
                "diameter_inches": route.diameter_inches,
                "material": route.material,
                "length_miles": float(route.length_miles) if route.length_miles else None,
            })
        
        response.append({
            "id": system.id,
            "name": system.name,
            "operator_name": system.operator_name,
            "product": system.product or "Crude Oil",
            "region": system.region,
            "route_count": len(routes),
            "routes": routes_list,
            "bbox": bbox.dict() if bbox else None,
        })
    
    return response


@router.get("/pipelines", response_model=List[schemas.PipelineSystemSummary])
async def list_pipeline_systems(
    session: AsyncSession = Depends(get_db),
    operator: Optional[str] = Query(None, description="Filter by operator name")
):
    """
    List all pipeline systems with metadata.
    
    Query Parameters:
    - operator: Filter by operator name (optional)
    
    Returns: List of pipeline systems with route counts and bounding boxes.
    """
    stmt = select(PipelineSystem)
    
    if operator:
        stmt = stmt.where(PipelineSystem.operator_name.ilike(f"%{operator}%"))
    
    result = await session.execute(stmt)
    systems = result.scalars().all()
    
    response = []
    for system in systems:
        # Count routes for this system
        route_stmt = select(func.count(PipelineRoute.id)).where(
            PipelineRoute.system_id == system.id
        )
        route_result = await session.execute(route_stmt)
        route_count = route_result.scalar() or 0
        
        # Get bbox of all routes in system
        bbox_stmt = select(
            func.ST_XMin(func.ST_Extent(PipelineRoute.geom)).label('min_lon'),
            func.ST_YMin(func.ST_Extent(PipelineRoute.geom)).label('min_lat'),
            func.ST_XMax(func.ST_Extent(PipelineRoute.geom)).label('max_lon'),
            func.ST_YMax(func.ST_Extent(PipelineRoute.geom)).label('max_lat'),
        ).where(PipelineRoute.system_id == system.id)
        
        bbox_result = await session.execute(bbox_stmt)
        bbox_row = bbox_result.one_or_none()
        
        bbox = None
        if bbox_row and bbox_row.min_lon:
            bbox = schemas.BoundingBox(
                min_lon=float(bbox_row.min_lon),
                min_lat=float(bbox_row.min_lat),
                max_lon=float(bbox_row.max_lon),
                max_lat=float(bbox_row.max_lat),
            )
        
        response.append(schemas.PipelineSystemSummary(
            id=system.id,
            name=system.name,
            operator_name=system.operator_name,
            product=system.product or "Crude Oil",
            region=system.region,
            route_count=route_count,
            bbox=bbox,
        ))
    
    return response


# ============================================================================
# Pipeline Routes Endpoints (GeoJSON for Mapbox)
# ============================================================================

@router.get("/pipelines/{route_id}")
async def get_route_geojson(
    route_id: int,
    session: AsyncSession = Depends(get_db)
):
    """
    Get a single route with full GeoJSON geometry.
    
    Returns: GeoJSON Feature with LineString geometry and route properties.
    """
    # Raw SQL using PostGIS ST_AsGeoJSON function
    stmt = text("""
        SELECT 
            id, system_id, name, from_measure, to_measure, 
            diameter_inches, material, grade, length_miles,
            ST_AsGeoJSON(geom) as geometry_json
        FROM pipelines_routes
        WHERE id = :route_id
    """).bindparams(route_id=route_id)
    
    result = await session.execute(stmt)
    row = result.first()
    
    if not row:
        raise HTTPException(status_code=404, detail="Route not found")
    
    # Parse the geometry JSON from PostGIS
    geom_dict = json.loads(row.geometry_json) if row.geometry_json else None
    
    # Get bbox
    bbox = await get_route_bbox(session, route_id)
    
    return {
        "type": "Feature",
        "id": row.id,
        "geometry": geom_dict,
        "properties": {
            "id": row.id,
            "system_id": row.system_id,
            "name": row.name,
            "from_measure": float(row.from_measure) if row.from_measure else 0,
            "to_measure": float(row.to_measure) if row.to_measure else None,
            "diameter_inches": row.diameter_inches,
            "material": row.material,
            "grade": row.grade,
            "length_miles": float(row.length_miles) if row.length_miles else None,
        },
        "bbox": bbox.dict() if bbox else None,
    }


@router.get("/pipelines/{route_id}/segments")
async def get_route_segments(
    route_id: int,
    session: AsyncSession = Depends(get_db)
):
    """
    Get all pipe segments for a route.
    
    Uses PostGIS ST_LineSubstring to dynamically calculate the geometry 
    of each segment based on its measure range.
    
    Returns: GeoJSON FeatureCollection with LineString features.
    """
    # Verify route exists and get its geometry and total measure range
    route_stmt = select(
        PipelineRoute.id,
        PipelineRoute.from_measure,
        PipelineRoute.to_measure,
        geofunc.ST_Length(geofunc.ST_Transform(PipelineRoute.geom, 3857)).label("geom_length_meters")
    ).where(PipelineRoute.id == route_id)
    
    route_result = await session.execute(route_stmt)
    route = route_result.first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    # Prefer explicit measures, fallback to geometric length if needed
    route_from = float(route.from_measure) if route.from_measure is not None else 0
    route_to = float(route.to_measure) if route.to_measure is not None else 0
    
    # If route_to is 0 or null, we might need to calculate it from segments or geometry
    if route_to <= 0:
        # Calculate max segment to_measure as a fallback
        max_seg_stmt = select(func.max(PipelineSegment.to_measure)).where(PipelineSegment.route_id == route_id)
        max_seg_res = await session.execute(max_seg_stmt)
        max_measure = max_seg_res.scalar()
        if max_measure:
            route_to = float(max_measure)
        else:
            # Absolute fallback to 1.0 for interpolation if no measures exist
            route_to = 1.0
            
    route_length = route_to - route_from
    
    if route_length <= 0:
        # Fallback if measures are not properly set
        stmt = select(PipelineSegment).where(PipelineSegment.route_id == route_id)
        result = await session.execute(stmt)
        segments = result.scalars().all()
        return {
            "type": "FeatureCollection",
            "features": [{
                "type": "Feature",
                "id": s.id,
                "geometry": None,
                "properties": {"id": s.id, "error": "Invalid route length"}
            } for s in segments]
        }

    # Query segments and use ST_LineSubstring to get their specific geometry
    # We must normalize the measures to 0.0 - 1.0 for ST_LineSubstring
    # We use COALESCE to handle nulls in from/to measures
    stmt = text("""
        SELECT 
            s.id, s.from_measure, s.to_measure, s.diameter_inches, 
            s.material, s.grade, s.wall_thickness_inches,
            ST_AsGeoJSON(
                ST_LineSubstring(
                    r.geom,
                    LEAST(GREATEST((s.from_measure - COALESCE(r.from_measure, 0)) / NULLIF(COALESCE(r.to_measure, :fallback_to) - COALESCE(r.from_measure, 0), 0), 0), 1),
                    LEAST(GREATEST((s.to_measure - COALESCE(r.from_measure, 0)) / NULLIF(COALESCE(r.to_measure, :fallback_to) - COALESCE(r.from_measure, 0), 0), 0), 1)
                )
            ) as segment_geom_json
        FROM pipelines_segments s
        JOIN pipelines_routes r ON s.route_id = r.id
        WHERE s.route_id = :route_id
        ORDER BY s.from_measure
    """).bindparams(route_id=route_id, fallback_to=route_to)
    
    result = await session.execute(stmt)
    rows = result.all()
    
    features = []
    for row in rows:
        features.append({
            "type": "Feature",
            "id": row.id,
            "geometry": json.loads(row.segment_geom_json) if row.segment_geom_json else None,
            "properties": {
                "id": row.id,
                "from_measure": float(row.from_measure),
                "to_measure": float(row.to_measure),
                "length": round(float(row.to_measure) - float(row.from_measure), 3),
                "diameter_inches": row.diameter_inches,
                "material": row.material,
                "grade": row.grade,
                "wall_thickness_inches": float(row.wall_thickness_inches) if row.wall_thickness_inches else None,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }


@router.get("/pipelines/{route_id}/stations")
async def get_route_stations(
    route_id: int,
    session: AsyncSession = Depends(get_db)
):
    """
    Get all stations on a route as GeoJSON with Point geometries.
    """
    stmt = text("""
        SELECT 
            id, name, station_type, measure, capacity_units, 
            capacity_value, operating_pressure_psi,
            ST_AsGeoJSON(geom) as geometry_json
        FROM pipelines_stations
        WHERE route_id = :route_id
        ORDER BY measure
    """).bindparams(route_id=route_id)
    
    result = await session.execute(stmt)
    rows = result.all()
    
    features = []
    for row in rows:
        features.append({
            "type": "Feature",
            "id": row.id,
            "geometry": json.loads(row.geometry_json) if row.geometry_json else None,
            "properties": {
                "id": row.id,
                "name": row.name,
                "station_type": row.station_type,
                "measure": float(row.measure),
                "capacity_units": row.capacity_units,
                "capacity_value": row.capacity_value,
                "operating_pressure_psi": row.operating_pressure_psi,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }


@router.get("/pipelines/{route_id}/valves")
async def get_route_valves(
    route_id: int,
    session: AsyncSession = Depends(get_db),
    valve_type: Optional[str] = Query(None, description="Filter by valve type")
):
    """
    Get all valves on a route as GeoJSON with Point geometries.
    """
    params = {"route_id": route_id}
    stmt_str = """
        SELECT 
            id, name, valve_type, normal_position, measure, 
            size_inches, rating_psi,
            ST_AsGeoJSON(geom) as geometry_json
        FROM pipelines_valves
        WHERE route_id = :route_id
    """
    if valve_type:
        stmt_str += " AND valve_type ILIKE :valve_type"
        params["valve_type"] = f"%{valve_type}%"
    
    stmt_str += " ORDER BY measure"
    
    stmt = text(stmt_str).bindparams(**params)
    
    result = await session.execute(stmt)
    rows = result.all()
    
    features = []
    for row in rows:
        features.append({
            "type": "Feature",
            "id": row.id,
            "geometry": json.loads(row.geometry_json) if row.geometry_json else None,
            "properties": {
                "id": row.id,
                "name": row.name or f"Valve MP{row.measure}",
                "valve_type": row.valve_type,
                "normal_position": row.normal_position,
                "measure": float(row.measure),
                "size_inches": float(row.size_inches) if row.size_inches else None,
                "rating_psi": row.rating_psi,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }


@router.get("/pipelines/{route_id}/devices")
async def get_route_devices(
    route_id: int,
    session: AsyncSession = Depends(get_db),
    device_type: Optional[str] = Query(None, description="Filter by device type")
):
    """
    Get all inline devices on a route as GeoJSON with Point geometries.
    """
    params = {"route_id": route_id}
    stmt_str = """
        SELECT 
            id, name, device_type, measure, capacity_units, capacity_value,
            ST_AsGeoJSON(geom) as geometry_json
        FROM pipelines_inline_devices
        WHERE route_id = :route_id
    """
    if device_type:
        stmt_str += " AND device_type ILIKE :device_type"
        params["device_type"] = f"%{device_type}%"
        
    stmt_str += " ORDER BY measure"
    
    stmt = text(stmt_str).bindparams(**params)
    
    result = await session.execute(stmt)
    rows = result.all()
    
    features = []
    for row in rows:
        features.append({
            "type": "Feature",
            "id": row.id,
            "geometry": json.loads(row.geometry_json) if row.geometry_json else None,
            "properties": {
                "id": row.id,
                "name": row.name or f"Device MP{row.measure}",
                "device_type": row.device_type,
                "measure": float(row.measure),
                "capacity_units": row.capacity_units,
                "capacity_value": float(row.capacity_value) if row.capacity_value else None,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }


# ============================================================================
# Spatial Queries (Advanced GIS Features)
# ============================================================================

@router.get("/routes-near-point")
async def get_routes_near_point(
    longitude: float = Query(..., description="Point longitude"),
    latitude: float = Query(..., description="Point latitude"),
    distance_miles: float = Query(10, description="Search radius in miles"),
    session: AsyncSession = Depends(get_db)
):
    """
    Find all routes within a certain distance of a point.
    
    Uses ST_DWithin for efficient spatial filtering.
    Distance is converted from miles to degrees (~1 degree ~ 69 miles).
    """
    distance_degrees = distance_miles / 69.0
    
    stmt = select(PipelineRoute).where(
        func.ST_DWithin(
            PipelineRoute.geom,
            func.ST_Point(longitude, latitude, 4326),
            distance_degrees,
            True  # Use spheroid (earth model) for accurate distances
        )
    )
    
    result = await session.execute(stmt)
    routes = result.scalars().all()
    
    features = []
    for route in routes:
        geom_dict = geometry_to_geojson(route.geom)
        features.append({
            "type": "Feature",
            "id": route.id,
            "geometry": geom_dict,
            "properties": {
                "id": route.id,
                "name": route.name,
                "operator": route.system_id,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }


@router.get("/routes-in-bounds")
async def get_routes_in_bounds(
    min_lon: float = Query(...),
    min_lat: float = Query(...),
    max_lon: float = Query(...),
    max_lat: float = Query(...),
    session: AsyncSession = Depends(get_db)
):
    """
    Find all routes within a bounding box.
    
    Uses ST_Intersects for efficient spatial filtering.
    """
    bbox = func.ST_MakeEnvelope(min_lon, min_lat, max_lon, max_lat, 4326)
    
    stmt = select(PipelineRoute).where(
        func.ST_Intersects(PipelineRoute.geom, bbox)
    )
    
    result = await session.execute(stmt)
    routes = result.scalars().all()
    
    features = []
    for route in routes:
        geom_dict = geometry_to_geojson(route.geom)
        features.append({
            "type": "Feature",
            "id": route.id,
            "geometry": geom_dict,
            "properties": {
                "id": route.id,
                "name": route.name,
                "system_id": route.system_id,
            }
        })
    
    return {
        "type": "FeatureCollection",
        "features": features,
    }
