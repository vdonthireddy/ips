"""
Pydantic schemas for request/response validation.
Includes GeoJSON Feature and FeatureCollection schemas.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime


# ============================================================================
# Base Response Models (non-geographic data)
# ============================================================================

class PipelineSystemBase(BaseModel):
    name: str
    operator_name: str
    product: Optional[str] = "Crude Oil"
    region: Optional[str] = None


class PipelineSystemResponse(PipelineSystemBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class PipelineSegmentBase(BaseModel):
    route_id: int
    from_measure: float
    to_measure: float
    diameter_inches: Optional[int] = None
    wall_thickness_inches: Optional[float] = None
    material: Optional[str] = None
    grade: Optional[str] = None
    coating: Optional[str] = None
    joint_type: Optional[str] = None
    installation_year: Optional[int] = None
    operating_pressure_psi: Optional[int] = None


class PipelineSegmentResponse(PipelineSegmentBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class PipelineStationBase(BaseModel):
    name: str
    station_type: str  # compressor, pump, regulator, reception, delivery
    measure: float
    capacity_units: Optional[str] = None
    capacity_value: Optional[int] = None
    operating_pressure_psi: Optional[int] = None


class PipelineStationResponse(PipelineStationBase):
    id: int
    route_id: int
    system_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class PipelineValveBase(BaseModel):
    name: Optional[str] = None
    valve_type: str  # isolation, block, check, relief, regulator
    normal_position: Optional[str] = None
    measure: float
    size_inches: Optional[float] = None
    rating_psi: Optional[int] = None


class PipelineValveResponse(PipelineValveBase):
    id: int
    route_id: int
    station_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class PipelineInlineDeviceBase(BaseModel):
    name: Optional[str] = None
    device_type: str  # meter, scraper_trap, separator, heater
    measure: float
    capacity_units: Optional[str] = None
    capacity_value: Optional[float] = None


class PipelineInlineDeviceResponse(PipelineInlineDeviceBase):
    id: int
    route_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# GeoJSON Models (for Mapbox compatibility)
# ============================================================================

class GeometryPoint(BaseModel):
    """GeoJSON Point geometry."""
    type: str = "Point"
    coordinates: List[float]  # [longitude, latitude]


class GeometryLineString(BaseModel):
    """GeoJSON LineString geometry."""
    type: str = "LineString"
    coordinates: List[List[float]]  # [[lon, lat], [lon, lat], ...]


class GeoJSONFeatureProperties(BaseModel):
    """Flexible properties for GeoJSON features."""
    model_config = {"extra": "allow"}


class GeoJSONFeature(BaseModel):
    """Standard GeoJSON Feature."""
    type: str = "Feature"
    geometry: Dict[str, Any]  # GeometryPoint or GeometryLineString
    properties: Dict[str, Any]
    id: Optional[int] = None


class GeoJSONFeatureCollection(BaseModel):
    """Standard GeoJSON FeatureCollection (output format for Mapbox)."""
    type: str = "FeatureCollection"
    features: List[GeoJSONFeature]


# ============================================================================
# Route Responses with Geometry
# ============================================================================

class PipelineRouteBase(BaseModel):
    system_id: int
    name: str
    from_measure: float = 0
    to_measure: Optional[float] = None
    diameter_inches: Optional[int] = None
    material: Optional[str] = None
    grade: Optional[str] = None
    length_miles: Optional[float] = None


class PipelineRouteResponse(PipelineRouteBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class PipelineRouteGeoResponse(BaseModel):
    """Pipeline route with GeoJSON geometry for Mapbox."""
    id: int
    system_id: int
    name: str
    from_measure: float
    to_measure: Optional[float]
    diameter_inches: Optional[int]
    material: Optional[str]
    grade: Optional[str]
    length_miles: Optional[float]
    created_at: datetime
    geometry: Dict[str, Any]  # GeoJSON LineString


# ============================================================================
# Collection Responses (multiple features as GeoJSON)
# ============================================================================

class StationsGeoJSONResponse(BaseModel):
    """Collection of stations as GeoJSON FeatureCollection."""
    type: str = "FeatureCollection"
    features: List[Dict[str, Any]]  # Each feature has geometry and properties


class ValvesGeoJSONResponse(BaseModel):
    """Collection of valves as GeoJSON FeatureCollection."""
    type: str = "FeatureCollection"
    features: List[Dict[str, Any]]


class SegmentsGeoJSONResponse(BaseModel):
    """Collection of segments as GeoJSON FeatureCollection."""
    type: str = "FeatureCollection"
    features: List[Dict[str, Any]]


class DevicesGeoJSONResponse(BaseModel):
    """Collection of inline devices as GeoJSON FeatureCollection."""
    type: str = "FeatureCollection"
    features: List[Dict[str, Any]]


# ============================================================================
# Composite Responses
# ============================================================================

class PipelineDetailResponse(BaseModel):
    """Complete pipeline route with all related features."""
    route: PipelineRouteGeoResponse
    segments: List[Dict[str, Any]]
    stations: List[Dict[str, Any]]
    valves: List[Dict[str, Any]]
    devices: List[Dict[str, Any]]


class BoundingBox(BaseModel):
    """Bounding box for a route."""
    min_lon: float
    min_lat: float
    max_lon: float
    max_lat: float


class PipelineSystemSummary(BaseModel):
    """Summary of a pipeline system with metadata."""
    id: int
    name: str
    operator_name: str
    product: str
    region: Optional[str]
    route_count: int
    bbox: Optional[BoundingBox] = None
