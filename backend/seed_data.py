"""
Pipeline System Seed Data Generator
Creates realistic pipeline infrastructure data for testing and development.
Usage:
  - Direct import: from seed_data import seed_database()
  - Command line: python seed_data.py
"""

from datetime import datetime
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Create synchronous engine for seeding
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/pipeline_db")
# Convert async URL to sync URL
sync_url = DATABASE_URL.replace("postgresql+asyncpg", "postgresql")
engine = create_engine(sync_url, echo=False)
SessionLocal = sessionmaker(bind=engine)

# Comprehensive realistic pipeline data
PIPELINE_SYSTEMS = [
    {
        "name": "Midstream Crude Network",
        "operator_name": "Energy Transport Corp",
        "product": "Crude Oil",
        "region": "Permian Basin",
    },
    {
        "name": "GasFlow Interstate System",
        "operator_name": "GasFlow Inc",
        "product": "Natural Gas",
        "region": "Texas Panhandle",
    },
    {
        "name": "Eagle Ford Liquids",
        "operator_name": "Frontier Energy",
        "product": "Natural Gas Liquids",
        "region": "South Texas",
    },
    {
        "name": "Bakken Express",
        "operator_name": "Northern Plains Pipelines",
        "product": "Crude Oil",
        "region": "North Dakota",
    },
    {
        "name": "Colorado Gas Main",
        "operator_name": "Rocky Mountain Gas",
        "product": "Natural Gas",
        "region": "Colorado",
    },
]

ROUTES = [
    # Midstream Crude Network routes
    {
        "system_id": 1,
        "name": "Permian Main Trunk",
        "product": "Crude Oil",
        "capacity_bpd": 500000,
        "diameter_inches": 30,
        "length_miles": 350,
        "geom": "LINESTRING(-102.0779 29.7604, -99.2433 31.2091, -95.3698 30.2672)",
    },
    {
        "system_id": 1,
        "name": "West Texas Branch",
        "product": "Crude Oil",
        "capacity_bpd": 250000,
        "diameter_inches": 24,
        "length_miles": 55,
        "geom": "LINESTRING(-102.0779 29.7604, -101.8821 29.5764)",
    },
    {
        "system_id": 1,
        "name": "New Mexico Extension",
        "product": "Crude Oil",
        "capacity_bpd": 180000,
        "diameter_inches": 20,
        "length_miles": 85,
        "geom": "LINESTRING(-102.0779 29.7604, -103.2258 28.8066)",
    },
    # GasFlow Interstate routes
    {
        "system_id": 2,
        "name": "OK-KS Gas Corridor",
        "product": "Natural Gas",
        "capacity_mmbtu": 2500,
        "diameter_inches": 36,
        "length_miles": 120,
        "geom": "LINESTRING(-99.3033 35.4676, -97.5164 37.0842)",
    },
    {
        "system_id": 2,
        "name": "Panhandle Primary",
        "product": "Natural Gas",
        "capacity_mmbtu": 1800,
        "diameter_inches": 30,
        "length_miles": 95,
        "geom": "LINESTRING(-101.5 35.5, -100.2 36.1)",
    },
    # Eagle Ford routes
    {
        "system_id": 3,
        "name": "Eagle Ford to Gulf",
        "product": "Natural Gas Liquids",
        "capacity_bpd": 150000,
        "diameter_inches": 16,
        "length_miles": 110,
        "geom": "LINESTRING(-97.9 27.8, -94.5 29.3)",
    },
    # Bakken routes
    {
        "system_id": 4,
        "name": "Bakken Central Gather",
        "product": "Crude Oil",
        "capacity_bpd": 400000,
        "diameter_inches": 28,
        "length_miles": 200,
        "geom": "LINESTRING(-103.5 48.5, -102.1 48.8)",
    },
    # Colorado routes
    {
        "system_id": 5,
        "name": "Colorado Front Range",
        "product": "Natural Gas",
        "capacity_mmbtu": 1500,
        "diameter_inches": 24,
        "length_miles": 75,
        "geom": "LINESTRING(-105.0 40.0, -104.5 40.5)",
    },
]

SEGMENTS = [
    # Permian Main Trunk segments
    {
        "route_id": 1,
        "name": "Odessa to Midland",
        "start_measure": 0,
        "end_measure": 45,
        "geom": "LINESTRING(-102.0779 29.7604, -101.9151 31.7500)",
    },
    {
        "route_id": 1,
        "name": "Midland to Abilene",
        "start_measure": 45,
        "end_measure": 150,
        "geom": "LINESTRING(-101.9151 31.7500, -99.7176 32.2477)",
    },
    {
        "route_id": 1,
        "name": "Abilene to Fort Worth",
        "start_measure": 150,
        "end_measure": 280,
        "geom": "LINESTRING(-99.7176 32.2477, -97.3331 32.7555)",
    },
    {
        "route_id": 1,
        "name": "Fort Worth to Terminal",
        "start_measure": 280,
        "end_measure": 350,
        "geom": "LINESTRING(-97.3331 32.7555, -95.3698 30.2672)",
    },
    # West Texas Branch
    {
        "route_id": 2,
        "name": "Odessa Local Feeder",
        "start_measure": 0,
        "end_measure": 55,
        "geom": "LINESTRING(-102.0779 29.7604, -101.8821 29.5764)",
    },
    # OK-KS Gas Corridor
    {
        "route_id": 4,
        "name": "Oklahoma Section",
        "start_measure": 0,
        "end_measure": 70,
        "geom": "LINESTRING(-99.3033 35.4676, -98.1000 36.2000)",
    },
    {
        "route_id": 4,
        "name": "Kansas Section",
        "start_measure": 70,
        "end_measure": 120,
        "geom": "LINESTRING(-98.1000 36.2000, -97.5164 37.0842)",
    },
]

STATIONS = [
    # Permian Main Trunk stations
    {
        "route_id": 1,
        "name": "Odessa Pump Station",
        "station_type": "pump",
        "measure": 5,
        "operating_pressure_psi": 850,
        "capacity": 500000,
        "geom": "POINT(-102.0779 29.8604)",
    },
    {
        "route_id": 1,
        "name": "Midland Measurement",
        "station_type": "measurement",
        "measure": 50,
        "operating_pressure_psi": 820,
        "geom": "POINT(-101.9151 31.7500)",
    },
    {
        "route_id": 1,
        "name": "Abilene Pump #1",
        "station_type": "pump",
        "measure": 160,
        "operating_pressure_psi": 900,
        "capacity": 500000,
        "geom": "POINT(-99.7176 32.2477)",
    },
    {
        "route_id": 1,
        "name": "Fort Worth Pressure Control",
        "station_type": "regulator",
        "measure": 290,
        "operating_pressure_psi": 750,
        "geom": "POINT(-97.3331 32.7555)",
    },
    {
        "route_id": 1,
        "name": "Houston Terminal Reception",
        "station_type": "reception",
        "measure": 345,
        "operating_pressure_psi": 50,
        "geom": "POINT(-95.3698 30.2672)",
    },
    # West Texas Branch
    {
        "route_id": 2,
        "name": "West Texas Pump",
        "station_type": "pump",
        "measure": 10,
        "operating_pressure_psi": 900,
        "capacity": 250000,
        "geom": "POINT(-101.9800 29.6800)",
    },
    {
        "route_id": 2,
        "name": "Andrews Delivery",
        "station_type": "delivery",
        "measure": 50,
        "operating_pressure_psi": 100,
        "geom": "POINT(-101.8821 29.5764)",
    },
    # OK-KS Gas Corridor
    {
        "route_id": 4,
        "name": "Oklahoma City Compressor",
        "station_type": "compressor",
        "measure": 20,
        "operating_pressure_psi": 950,
        "capacity": 500,
        "geom": "POINT(-97.5169 35.4676)",
    },
    {
        "route_id": 4,
        "name": "Kansas Compressor Station",
        "station_type": "compressor",
        "measure": 100,
        "operating_pressure_psi": 1050,
        "capacity": 600,
        "geom": "POINT(-97.8000 36.8000)",
    },
    # Eagle Ford
    {
        "route_id": 6,
        "name": "Eagle Ford Pump Station",
        "station_type": "pump",
        "measure": 25,
        "operating_pressure_psi": 880,
        "capacity": 150000,
        "geom": "POINT(-97.8000 27.9000)",
    },
]

VALVES = [
    # Permian Main Trunk valves
    {
        "route_id": 1,
        "name": "Odessa Block Valve 001",
        "valve_type": "gate",
        "measure": 2,
        "position": "open",
        "operating_pressure_psi": 850,
        "size_inches": 30,
        "geom": "POINT(-102.0700 29.7650)",
    },
    {
        "route_id": 1,
        "name": "Midland Check Valve 002",
        "valve_type": "check",
        "measure": 48,
        "position": "open",
        "operating_pressure_psi": 820,
        "size_inches": 30,
        "geom": "POINT(-101.9000 31.7500)",
    },
    {
        "route_id": 1,
        "name": "Abilene Block Valve 003",
        "valve_type": "gate",
        "measure": 155,
        "position": "open",
        "operating_pressure_psi": 900,
        "size_inches": 30,
        "geom": "POINT(-99.7100 32.2500)",
    },
    {
        "route_id": 1,
        "name": "Abilene Pressure Relief",
        "valve_type": "relief",
        "measure": 165,
        "position": "open",
        "operating_pressure_psi": 900,
        "size_inches": 4,
        "geom": "POINT(-99.7200 32.2400)",
    },
    {
        "route_id": 1,
        "name": "Fort Worth Block Valve 004",
        "valve_type": "gate",
        "measure": 285,
        "position": "open",
        "operating_pressure_psi": 750,
        "size_inches": 30,
        "geom": "POINT(-97.3400 32.7500)",
    },
    {
        "route_id": 1,
        "name": "Fort Worth Blowdown 001",
        "valve_type": "blowdown",
        "measure": 292,
        "position": "closed",
        "operating_pressure_psi": 0,
        "size_inches": 2,
        "geom": "POINT(-97.3200 32.7600)",
    },
    {
        "route_id": 1,
        "name": "Houston Terminal Block",
        "valve_type": "gate",
        "measure": 348,
        "position": "open",
        "operating_pressure_psi": 50,
        "size_inches": 36,
        "geom": "POINT(-95.3600 30.2700)",
    },
    # West Texas Branch
    {
        "route_id": 2,
        "name": "West Texas Block Valve",
        "valve_type": "gate",
        "measure": 8,
        "position": "open",
        "operating_pressure_psi": 900,
        "size_inches": 24,
        "geom": "POINT(-101.9900 29.6700)",
    },
    {
        "route_id": 2,
        "name": "Andrews Inlet Check",
        "valve_type": "check",
        "measure": 52,
        "position": "open",
        "operating_pressure_psi": 100,
        "size_inches": 24,
        "geom": "POINT(-101.8700 29.5800)",
    },
    # OK-KS Gas Corridor
    {
        "route_id": 4,
        "name": "Oklahoma Block Valve",
        "valve_type": "gate",
        "measure": 15,
        "position": "open",
        "operating_pressure_psi": 950,
        "size_inches": 36,
        "geom": "POINT(-97.6000 35.3500)",
    },
    {
        "route_id": 4,
        "name": "Kansas Inlet Check",
        "valve_type": "check",
        "measure": 105,
        "position": "open",
        "operating_pressure_psi": 1050,
        "size_inches": 36,
        "geom": "POINT(-97.7500 36.9000)",
    },
    {
        "route_id": 4,
        "name": "Kansas Relief Valve",
        "valve_type": "relief",
        "measure": 108,
        "position": "open",
        "operating_pressure_psi": 1050,
        "size_inches": 6,
        "geom": "POINT(-97.7300 36.9100)",
    },
]

DEVICES = [
    # Inline devices
    {
        "route_id": 1,
        "name": "Odessa Scraper Trap In",
        "device_type": "scraper_trap",
        "measure": 1,
        "status": "active",
        "geom": "POINT(-102.0750 29.7620)",
    },
    {
        "route_id": 1,
        "name": "Midland Flow Meter",
        "device_type": "flow_meter",
        "measure": 50,
        "status": "active",
        "geom": "POINT(-101.9100 31.7510)",
    },
    {
        "route_id": 1,
        "name": "Fort Worth Scraper Trap Out",
        "device_type": "scraper_trap",
        "measure": 349,
        "status": "active",
        "geom": "POINT(-95.3700 30.2650)",
    },
    {
        "route_id": 2,
        "name": "West Texas Flow Meter",
        "device_type": "flow_meter",
        "measure": 30,
        "status": "active",
        "geom": "POINT(-101.9800 29.5800)",
    },
]


def seed_database():
    """Seed the database with realistic pipeline data."""
    session = SessionLocal()
    
    try:
        # Clear existing data (optional - remove if you want to keep historical data)
        session.execute(text("DELETE FROM pipelines_inline_devices;"))
        session.execute(text("DELETE FROM pipelines_valves;"))
        session.execute(text("DELETE FROM pipelines_stations;"))
        session.execute(text("DELETE FROM pipelines_segments;"))
        session.execute(text("DELETE FROM pipelines_routes;"))
        session.execute(text("DELETE FROM pipelines_systems;"))
        
        print("✓ Cleared existing data")
        
        # Insert pipeline systems
        for system in PIPELINE_SYSTEMS:
            result = session.execute(
                text("""
                    INSERT INTO pipelines_systems (name, operator_name, product, region)
                    VALUES (:name, :operator_name, :product, :region)
                    RETURNING id
                """),
                system
            )
            system["id"] = result.scalar()
        
        print(f"✓ Added {len(PIPELINE_SYSTEMS)} pipeline systems")
        
        # Insert routes
        for route in ROUTES:
            result = session.execute(
                text("""
                    INSERT INTO pipelines_routes 
                    (system_id, name, product, capacity_bpd, capacity_mmbtu, diameter_inches, length_miles, geom)
                    VALUES 
                    (:system_id, :name, :product, :capacity_bpd, :capacity_mmbtu, :diameter_inches, :length_miles, 
                     ST_GeomFromText(:geom, 4326))
                    RETURNING id
                """),
                {
                    **route,
                    "capacity_mmbtu": route.get("capacity_mmbtu"),
                    "capacity_bpd": route.get("capacity_bpd"),
                }
            )
            route["id"] = result.scalar()
        
        print(f"✓ Added {len(ROUTES)} routes")
        
        # Insert segments
        for segment in SEGMENTS:
            session.execute(
                text("""
                    INSERT INTO pipelines_segments 
                    (route_id, name, start_measure, end_measure, geom)
                    VALUES (:route_id, :name, :start_measure, :end_measure, ST_GeomFromText(:geom, 4326))
                """),
                segment
            )
        
        print(f"✓ Added {len(SEGMENTS)} segments")
        
        # Insert stations
        for station in STATIONS:
            session.execute(
                text("""
                    INSERT INTO pipelines_stations 
                    (route_id, name, station_type, measure, operating_pressure_psi, capacity, geom)
                    VALUES (:route_id, :name, :station_type, :measure, :operating_pressure_psi, :capacity, 
                            ST_GeomFromText(:geom, 4326))
                """),
                station
            )
        
        print(f"✓ Added {len(STATIONS)} stations")
        
        # Insert valves
        for valve in VALVES:
            session.execute(
                text("""
                    INSERT INTO pipelines_valves 
                    (route_id, name, valve_type, measure, position, operating_pressure_psi, size_inches, geom)
                    VALUES (:route_id, :name, :valve_type, :measure, :position, :operating_pressure_psi, 
                            :size_inches, ST_GeomFromText(:geom, 4326))
                """),
                valve
            )
        
        print(f"✓ Added {len(VALVES)} valves")
        
        # Insert devices
        for device in DEVICES:
            session.execute(
                text("""
                    INSERT INTO pipelines_inline_devices 
                    (route_id, name, device_type, measure, status, geom)
                    VALUES (:route_id, :name, :device_type, :measure, :status, ST_GeomFromText(:geom, 4326))
                """),
                device
            )
        
        print(f"✓ Added {len(DEVICES)} devices")
        
        session.commit()
        print("\n✅ Database seeding completed successfully!")
        
        # Print summary
        stats = session.execute(text("""
            SELECT
                (SELECT COUNT(*) FROM pipelines_systems) as systems,
                (SELECT COUNT(*) FROM pipelines_routes) as routes,
                (SELECT COUNT(*) FROM pipelines_segments) as segments,
                (SELECT COUNT(*) FROM pipelines_stations) as stations,
                (SELECT COUNT(*) FROM pipelines_valves) as valves,
                (SELECT COUNT(*) FROM pipelines_inline_devices) as devices
        """)).first()
        
        print(f"\nDatabase Summary:")
        print(f"  Systems: {stats.systems}")
        print(f"  Routes: {stats.routes}")
        print(f"  Segments: {stats.segments}")
        print(f"  Stations: {stats.stations}")
        print(f"  Valves: {stats.valves}")
        print(f"  Devices: {stats.devices}")
        
    except Exception as e:
        session.rollback()
        print(f"❌ Error seeding database: {e}")
        raise
    finally:
        session.close()


if __name__ == "__main__":
    seed_database()
