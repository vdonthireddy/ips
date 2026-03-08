-- PostgreSQL + PostGIS Schema for Intelligent Pipeline System
-- PODS-inspired data model for pipeline infrastructure

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Pipeline Systems (operators, companies)
CREATE TABLE pipelines_systems (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  operator_name VARCHAR(255) NOT NULL,
  product VARCHAR(100) DEFAULT 'Crude Oil', -- crude oil, natural gas, refined products, etc.
  region VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(operator_name, name)
);

-- Pipeline Routes (main pipeline infrastructure)
CREATE TABLE pipelines_routes (
  id SERIAL PRIMARY KEY,
  system_id INTEGER NOT NULL REFERENCES pipelines_systems(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  -- LINESTRING geometry in WGS84 (EPSG:4326) for Mapbox compatibility
  geom GEOMETRY(LINESTRING, 4326) NOT NULL,
  from_measure NUMERIC(10, 2) DEFAULT 0,  -- miles or km
  to_measure NUMERIC(10, 2),
  diameter_inches INTEGER,
  material VARCHAR(50), -- Steel, Composite, etc.
  grade VARCHAR(50),    -- API 5L X52, X60, etc.
  length_miles NUMERIC(10, 2),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(system_id, name)
);

-- Pipe Segments (individual segments of routes with attributes)
CREATE TABLE pipelines_segments (
  id SERIAL PRIMARY KEY,
  route_id INTEGER NOT NULL REFERENCES pipelines_routes(id) ON DELETE CASCADE,
  from_measure NUMERIC(10, 2) NOT NULL,
  to_measure NUMERIC(10, 2) NOT NULL,
  diameter_inches INTEGER,
  wall_thickness_inches NUMERIC(5, 3),
  material VARCHAR(50),
  grade VARCHAR(50),
  coating VARCHAR(100),
  joint_type VARCHAR(50),
  installation_year INTEGER,
  operating_pressure_psi INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  CHECK (to_measure > from_measure)
);

-- Pipeline Stations (compressor, pump, receiving/delivery stations)
CREATE TABLE pipelines_stations (
  id SERIAL PRIMARY KEY,
  system_id INTEGER NOT NULL REFERENCES pipelines_systems(id) ON DELETE CASCADE,
  route_id INTEGER NOT NULL REFERENCES pipelines_routes(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  station_type VARCHAR(50) NOT NULL, -- compressor, pump, regulator, reception, delivery
  geom GEOMETRY(POINT, 4326) NOT NULL,
  measure NUMERIC(10, 2) NOT NULL,  -- location along route
  capacity_units VARCHAR(50),       -- bhp, gpm, scf/day
  capacity_value INTEGER,
  operating_pressure_psi INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(route_id, measure)
);

-- Pipeline Valves (isolation, block, check, pressure relief, etc.)
CREATE TABLE pipelines_valves (
  id SERIAL PRIMARY KEY,
  station_id INTEGER REFERENCES pipelines_stations(id) ON DELETE SET NULL,
  route_id INTEGER NOT NULL REFERENCES pipelines_routes(id) ON DELETE CASCADE,
  name VARCHAR(255),
  valve_type VARCHAR(50) NOT NULL, -- isolation, block, check, relief, regulator
  normal_position VARCHAR(20),      -- open, closed
  geom GEOMETRY(POINT, 4326) NOT NULL,
  measure NUMERIC(10, 2) NOT NULL,
  size_inches NUMERIC(5, 2),
  rating_psi INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(route_id, measure)
);

-- Inline Devices (meters, scraper traps, etc.)
CREATE TABLE pipelines_inline_devices (
  id SERIAL PRIMARY KEY,
  route_id INTEGER NOT NULL REFERENCES pipelines_routes(id) ON DELETE CASCADE,
  name VARCHAR(255),
  device_type VARCHAR(50) NOT NULL, -- meter, scraper_trap, separator, heater
  geom GEOMETRY(POINT, 4326) NOT NULL,
  measure NUMERIC(10, 2) NOT NULL,
  capacity_units VARCHAR(50),
  capacity_value NUMERIC(12, 2),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(route_id, measure)
);

-- Create spatial indexes for performance (GIST indexes for geometry columns)
CREATE INDEX idx_pipelines_routes_geom ON pipelines_routes USING GIST(geom);
CREATE INDEX idx_pipelines_stations_geom ON pipelines_stations USING GIST(geom);
CREATE INDEX idx_pipelines_valves_geom ON pipelines_valves USING GIST(geom);
CREATE INDEX idx_pipelines_inline_devices_geom ON pipelines_inline_devices USING GIST(geom);

-- Regular indexes for foreign keys and common queries
CREATE INDEX idx_pipelines_routes_system_id ON pipelines_routes(system_id);
CREATE INDEX idx_pipelines_segments_route_id ON pipelines_segments(route_id);
CREATE INDEX idx_pipelines_stations_route_id ON pipelines_stations(route_id);
CREATE INDEX idx_pipelines_stations_system_id ON pipelines_stations(system_id);
CREATE INDEX idx_pipelines_valves_route_id ON pipelines_valves(route_id);
CREATE INDEX idx_pipelines_inline_devices_route_id ON pipelines_inline_devices(route_id);

-- Materialized View: Get all features on a route (for efficient querying)
CREATE OR REPLACE VIEW route_features_view AS
SELECT 
  route_id,
  'station' as feature_type,
  id as feature_id,
  name,
  measure,
  geom,
  station_type as subtype
FROM pipelines_stations
UNION ALL
SELECT 
  route_id,
  'valve' as feature_type,
  id as feature_id,
  name,
  measure,
  geom,
  valve_type as subtype
FROM pipelines_valves
UNION ALL
SELECT 
  route_id,
  'device' as feature_type,
  id as feature_id,
  name,
  measure,
  geom,
  device_type as subtype
FROM pipelines_inline_devices;

-- ============================================================================
-- SAMPLE DATA: Realistic US Pipeline System (Permian Basin / Mid-Continent)
-- ============================================================================

-- Insert pipeline system
INSERT INTO pipelines_systems (name, operator_name, product, region) VALUES
('Midstream Crude Network', 'Energy Transport Corp', 'Crude Oil', 'Permian Basin'),
('Natural Gas Interstate', 'GasFlow Inc', 'Natural Gas', 'Mid-Continent');

-- Sample Route 1: Permian to Houston (crude oil)
-- Coordinates: Midland, TX (31.9973, -102.0779) to Houston, TX (29.7604, -95.3698)
INSERT INTO pipelines_routes (system_id, name, geom, from_measure, to_measure, diameter_inches, material, grade, length_miles) VALUES
(1, 
 'Permian Main Trunk',
 ST_GeomFromText('LINESTRING(-102.0779 31.9973, -101.8 31.95, -101.5 31.92, -101.0 31.88, -100.5 31.85, -100.0 31.87, -99.5 31.90, -99.0 31.95, -98.5 32.05, -98.0 32.15, -97.5 32.35, -97.0 32.55, -96.5 32.75, -96.0 32.95, -95.5 29.85, -95.3698 29.7604)', 4326),
 0,
 380,
 16,
 'Steel',
 'API 5L X52',
 350
);

-- Sample Route 2: Secondary pipeline network
INSERT INTO pipelines_routes (system_id, name, geom, from_measure, to_measure, diameter_inches, material, grade, length_miles) VALUES
(1,
 'West Texas Branch',
 ST_GeomFromText('LINESTRING(-102.0779 31.9973, -101.5 32.5, -101.2 33.0, -100.9 33.3)', 4326),
 0,
 55,
 12,
 'Steel',
 'API 5L X42',
 55
);

-- Sample Route 3: Natural Gas system
INSERT INTO pipelines_routes (system_id, name, geom, from_measure, to_measure, diameter_inches, material, grade, length_miles) VALUES
(2,
 'Oklahoma to Kansas Gas Main',
 ST_GeomFromText('LINESTRING(-96.9 36.0, -96.5 36.2, -96.0 36.5, -95.5 36.8, -95.2 37.0, -94.9 37.2)', 4326),
 0,
 120,
 30,
 'Steel',
 'API 5L X60',
 120
);

-- ============================================================================
-- Insert pipe segments for Route 1
-- ============================================================================
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, wall_thickness_inches, material, grade, coating, joint_type, installation_year, operating_pressure_psi) VALUES
(1, 0, 50, 16, 0.312, 'Steel', 'API 5L X52', 'Fusion Bonded Epoxy', 'ERW', 2005, 1200),
(1, 50, 100, 16, 0.312, 'Steel', 'API 5L X52', 'Fusion Bonded Epoxy', 'ERW', 2005, 1200),
(1, 100, 150, 16, 0.281, 'Steel', 'API 5L X42', 'Coal Tar Enamel', 'Seamless', 1998, 1150),
(1, 150, 200, 16, 0.281, 'Steel', 'API 5L X42', 'Coal Tar Enamel', 'ERW', 1998, 1150),
(1, 200, 250, 16, 0.312, 'Steel', 'API 5L X52', 'Fusion Bonded Epoxy', 'ERW', 2008, 1200),
(1, 250, 300, 16, 0.312, 'Steel', 'API 5L X52', 'Fusion Bonded Epoxy', 'ERW', 2008, 1200),
(1, 300, 350, 16, 0.250, 'Steel', 'API 5L X35', 'Paint', 'Seamless', 1995, 1000),
(1, 350, 380, 12, 0.281, 'Steel', 'API 5L X42', 'Fusion Bonded Epoxy', 'ERW', 2010, 1100);

-- ============================================================================
-- Insert stations for Route 1 (Compressor/Pump Stations)
-- ============================================================================
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, geom, measure, capacity_value, operating_pressure_psi) VALUES
(1, 1, 'Midland Pump Station', 'pump', ST_GeomFromText('POINT(-102.0779 31.9973)', 4326), 0, 3500, 1250),
(1, 1, 'Odessa Junction', 'regulator', ST_GeomFromText('POINT(-101.8 31.95)', 4326), 45, NULL, 1200),
(1, 1, 'Abilene Transfer', 'pump', ST_GeomFromText('POINT(-99.5 31.90)', 4326), 180, 2500, 1200),
(1, 1, 'Fort Worth Hub', 'regulator', ST_GeomFromText('POINT(-97.2 32.75)', 4326), 290, NULL, 1150),
(1, 1, 'Houston Terminal', 'delivery', ST_GeomFromText('POINT(-95.3698 29.7604)', 4326), 380, 5000, 150);

-- ============================================================================
-- Insert valves for Route 1
-- ============================================================================
INSERT INTO pipelines_valves (route_id, station_id, name, valve_type, normal_position, geom, measure, size_inches, rating_psi) VALUES
(1, 1, 'MP0-Block Valve', 'block', 'open', ST_GeomFromText('POINT(-102.0779 31.9973)', 4326), 0, 16, 1500),
(1, 2, 'MP45-Isolation', 'isolation', 'open', ST_GeomFromText('POINT(-101.75 31.94)', 4326), 43, 16, 1500),
(1, NULL, 'MP85-Check Valve', 'check', 'open', ST_GeomFromText('POINT(-101.0 31.88)', 4326), 85, 16, 1500),
(1, NULL, 'MP140-Isolation', 'isolation', 'open', ST_GeomFromText('POINT(-100.2 31.87)', 4326), 140, 16, 1500),
(1, 3, 'MP180-Block Valve', 'block', 'open', ST_GeomFromText('POINT(-99.5 31.90)', 4326), 180, 16, 1500),
(1, NULL, 'MP220-Check Valve', 'check', 'open', ST_GeomFromText('POINT(-98.8 32.05)', 4326), 220, 16, 1500),
(1, NULL, 'MP260-Isolation', 'isolation', 'open', ST_GeomFromText('POINT(-98.0 32.25)', 4326), 260, 16, 1500),
(1, NULL, 'MP300-Relief Valve', 'relief', 'closed', ST_GeomFromText('POINT(-97.0 32.55)', 4326), 300, 12, 1500),
(1, 4, 'MP290-Block Valve', 'block', 'open', ST_GeomFromText('POINT(-97.2 32.75)', 4326), 290, 16, 1500),
(1, NULL, 'MP350-Isolation', 'isolation', 'open', ST_GeomFromText('POINT(-96.2 32.88)', 4326), 350, 16, 1500),
(1, 5, 'MP380-Terminal Block', 'block', 'open', ST_GeomFromText('POINT(-95.3698 29.7604)', 4326), 380, 16, 1500);

-- ============================================================================
-- Insert inline devices (meters, etc.)
-- ============================================================================
INSERT INTO pipelines_inline_devices (route_id, name, device_type, geom, measure, capacity_units, capacity_value) VALUES
(1, 'Midland Flow Meter', 'meter', ST_GeomFromText('POINT(-102.0779 31.9973)', 4326), 2, 'bbl/day', 45000),
(1, 'Scraper Trap 1', 'scraper_trap', ST_GeomFromText('POINT(-101.2 31.92)', 4326), 65, NULL, NULL),
(1, 'Abilene Flow Meter', 'meter', ST_GeomFromText('POINT(-99.5 31.90)', 4326), 185, 'bbl/day', 43000),
(1, 'Houston Terminal Meter', 'meter', ST_GeomFromText('POINT(-95.3698 29.7604)', 4326), 378, 'bbl/day', 42500);

-- ============================================================================
-- Segments for Route 2 (West Texas Branch)
-- ============================================================================
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, wall_thickness_inches, material, grade, coating, joint_type, installation_year, operating_pressure_psi) VALUES
(2, 0, 30, 12, 0.281, 'Steel', 'API 5L X42', 'Fusion Bonded Epoxy', 'ERW', 2007, 1100),
(2, 30, 55, 12, 0.281, 'Steel', 'API 5L X42', 'Fusion Bonded Epoxy', 'ERW', 2007, 1100);

-- Stations for Route 2
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, geom, measure, capacity_value, operating_pressure_psi) VALUES
(1, 2, 'Midland Junction 2', 'pump', ST_GeomFromText('POINT(-102.0779 31.9973)', 4326), 0, 1500, 1100),
(1, 2, 'Lubbock Connection', 'regulator', ST_GeomFromText('POINT(-101.2 33.0)', 4326), 45, NULL, 1050);

-- Valves for Route 2
INSERT INTO pipelines_valves (route_id, station_id, name, valve_type, normal_position, geom, measure, size_inches, rating_psi) VALUES
(2, NULL, 'Branch Start Valve', 'block', 'open', ST_GeomFromText('POINT(-102.0779 31.9973)', 4326), 0, 12, 1500),
(2, NULL, 'Branch Mid Isolation', 'isolation', 'open', ST_GeomFromText('POINT(-101.5 32.5)', 4326), 25, 12, 1500),
(2, NULL, 'Branch End Valve', 'block', 'open', ST_GeomFromText('POINT(-100.9 33.3)', 4326), 55, 12, 1500);

-- ============================================================================
-- Segments for Route 3 (Natural Gas)
-- ============================================================================
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, wall_thickness_inches, material, grade, coating, joint_type, installation_year, operating_pressure_psi) VALUES
(3, 0, 60, 30, 0.375, 'Steel', 'API 5L X60', 'Fusion Bonded Epoxy', 'ERW', 2012, 1500),
(3, 60, 120, 30, 0.375, 'Steel', 'API 5L X60', 'Fusion Bonded Epoxy', 'ERW', 2012, 1500);

-- Stations for Route 3
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, geom, measure, capacity_value, operating_pressure_psi) VALUES
(2, 3, 'Oklahoma Compressor', 'compressor', ST_GeomFromText('POINT(-96.9 36.0)', 4326), 0, 5000, 1600),
(2, 3, 'Kansas Distribution', 'regulator', ST_GeomFromText('POINT(-94.9 37.2)', 4326), 120, NULL, 500);

-- Valves for Route 3
INSERT INTO pipelines_valves (route_id, station_id, name, valve_type, normal_position, geom, measure, size_inches, rating_psi) VALUES
(3, NULL, 'Gas Start Valve', 'block', 'open', ST_GeomFromText('POINT(-96.9 36.0)', 4326), 0, 30, 1600),
(3, NULL, 'Gas Isolation 1', 'isolation', 'open', ST_GeomFromText('POINT(-96.0 36.5)', 4326), 50, 30, 1600),
(3, NULL, 'Gas Check Valve', 'check', 'open', ST_GeomFromText('POINT(-95.2 37.0)', 4326), 95, 30, 1600),
(3, NULL, 'Gas End Valve', 'block', 'open', ST_GeomFromText('POINT(-94.9 37.2)', 4326), 120, 30, 1600);

-- Display insertion summary
SELECT 'Pipeline Systems: ' || COUNT(*) FROM pipelines_systems;
SELECT 'Pipeline Routes: ' || COUNT(*) FROM pipelines_routes;
SELECT 'Pipe Segments: ' || COUNT(*) FROM pipelines_segments;
SELECT 'Stations: ' || COUNT(*) FROM pipelines_stations;
SELECT 'Valves: ' || COUNT(*) FROM pipelines_valves;
SELECT 'Inline Devices: ' || COUNT(*) FROM pipelines_inline_devices;
