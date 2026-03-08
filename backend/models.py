"""
SQLAlchemy ORM models for pipeline infrastructure.
Uses GeoAlchemy2 for PostGIS geometry columns.
"""
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, DateTime, ForeignKey, Numeric, 
    CheckConstraint, UniqueConstraint, Index
)
from geoalchemy2 import Geometry
from database import Base


class PipelineSystem(Base):
    """Represents a pipeline system operated by a company."""
    __tablename__ = "pipelines_systems"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    operator_name = Column(String(255), nullable=False)
    product = Column(String(100), default="Crude Oil")  # crude oil, natural gas, etc.
    region = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('operator_name', 'name', name='uix_operator_pipeline'),
    )


class PipelineRoute(Base):
    """Main pipeline routes with geometry (LINESTRING)."""
    __tablename__ = "pipelines_routes"

    id = Column(Integer, primary_key=True, index=True)
    system_id = Column(Integer, ForeignKey("pipelines_systems.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    
    # PostGIS geometry: LINESTRING in WGS84 (EPSG:4326 for Mapbox compatibility)
    geom = Column(Geometry(geometry_type='LINESTRING', srid=4326), nullable=False)
    
    from_measure = Column(Numeric(10, 2), default=0)  # miles or km
    to_measure = Column(Numeric(10, 2), nullable=True)
    diameter_inches = Column(Integer, nullable=True)
    material = Column(String(50), nullable=True)
    grade = Column(String(50), nullable=True)  # API 5L grade
    length_miles = Column(Numeric(10, 2), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('system_id', 'name', name='uix_system_route'),
        Index('idx_pipelines_routes_system_id', 'system_id'),
        Index('idx_pipelines_routes_geom', 'geom', postgresql_using='gist'),
    )


class PipelineSegment(Base):
    """Individual pipe segments with attributes (diameter, wall thickness, coating, etc.)."""
    __tablename__ = "pipelines_segments"

    id = Column(Integer, primary_key=True, index=True)
    route_id = Column(Integer, ForeignKey("pipelines_routes.id", ondelete="CASCADE"), nullable=False)
    from_measure = Column(Numeric(10, 2), nullable=False)
    to_measure = Column(Numeric(10, 2), nullable=False)
    diameter_inches = Column(Integer, nullable=True)
    wall_thickness_inches = Column(Numeric(5, 3), nullable=True)
    material = Column(String(50), nullable=True)
    grade = Column(String(50), nullable=True)
    coating = Column(String(100), nullable=True)
    joint_type = Column(String(50), nullable=True)  # ERW, seamless, etc.
    installation_year = Column(Integer, nullable=True)
    operating_pressure_psi = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint('to_measure > from_measure'),
        Index('idx_pipelines_segments_route_id', 'route_id'),
    )


class PipelineStation(Base):
    """Stations (compressor, pump, regulator, delivery/reception points)."""
    __tablename__ = "pipelines_stations"

    id = Column(Integer, primary_key=True, index=True)
    system_id = Column(Integer, ForeignKey("pipelines_systems.id", ondelete="CASCADE"), nullable=False)
    route_id = Column(Integer, ForeignKey("pipelines_routes.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    station_type = Column(String(50), nullable=False)  # compressor, pump, regulator, reception, delivery
    
    # POINT geometry in WGS84
    geom = Column(Geometry(geometry_type='POINT', srid=4326), nullable=False)
    
    measure = Column(Numeric(10, 2), nullable=False)  # Location along route
    capacity_units = Column(String(50), nullable=True)  # bhp, gpm, scf/day
    capacity_value = Column(Integer, nullable=True)
    operating_pressure_psi = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('route_id', 'measure', name='uix_route_station_measure'),
        Index('idx_pipelines_stations_route_id', 'route_id'),
        Index('idx_pipelines_stations_system_id', 'system_id'),
        Index('idx_pipelines_stations_geom', 'geom', postgresql_using='gist'),
    )


class PipelineValve(Base):
    """Valves (isolation, block, check, relief, regulator)."""
    __tablename__ = "pipelines_valves"

    id = Column(Integer, primary_key=True, index=True)
    station_id = Column(Integer, ForeignKey("pipelines_stations.id", ondelete="SET NULL"), nullable=True)
    route_id = Column(Integer, ForeignKey("pipelines_routes.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=True)
    valve_type = Column(String(50), nullable=False)  # isolation, block, check, relief, regulator
    normal_position = Column(String(20), nullable=True)  # open, closed
    
    # POINT geometry
    geom = Column(Geometry(geometry_type='POINT', srid=4326), nullable=False)
    
    measure = Column(Numeric(10, 2), nullable=False)
    size_inches = Column(Numeric(5, 2), nullable=True)
    rating_psi = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('route_id', 'measure', name='uix_route_valve_measure'),
        Index('idx_pipelines_valves_route_id', 'route_id'),
        Index('idx_pipelines_valves_geom', 'geom', postgresql_using='gist'),
    )


class PipelineInlineDevice(Base):
    """Inline devices (meters, scraper traps, separators, heaters)."""
    __tablename__ = "pipelines_inline_devices"

    id = Column(Integer, primary_key=True, index=True)
    route_id = Column(Integer, ForeignKey("pipelines_routes.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=True)
    device_type = Column(String(50), nullable=False)  # meter, scraper_trap, separator, heater
    
    # POINT geometry
    geom = Column(Geometry(geometry_type='POINT', srid=4326), nullable=False)
    
    measure = Column(Numeric(10, 2), nullable=False)
    capacity_units = Column(String(50), nullable=True)
    capacity_value = Column(Numeric(12, 2), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('route_id', 'measure', name='uix_route_device_measure'),
        Index('idx_pipelines_inline_devices_route_id', 'route_id'),
        Index('idx_pipelines_inline_devices_geom', 'geom', postgresql_using='gist'),
    )
