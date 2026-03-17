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

-- Create spatial indexes
CREATE INDEX idx_pipelines_routes_geom ON pipelines_routes USING GIST(geom);
CREATE INDEX idx_pipelines_stations_geom ON pipelines_stations USING GIST(geom);
CREATE INDEX idx_pipelines_valves_geom ON pipelines_valves USING GIST(geom);
CREATE INDEX idx_pipelines_inline_devices_geom ON pipelines_inline_devices USING GIST(geom);

-- Regular indexes
CREATE INDEX idx_pipelines_routes_system_id ON pipelines_routes(system_id);
CREATE INDEX idx_pipelines_segments_route_id ON pipelines_segments(route_id);
CREATE INDEX idx_pipelines_stations_route_id ON pipelines_stations(route_id);

-- ============================================================================
-- FULL SEED DATA
-- ============================================================================

-- Systems
INSERT INTO pipelines_systems (id, name, operator_name, product, region) VALUES
(1, 'Midstream Crude Network', 'Energy Transport Corp', 'Crude Oil', 'Permian Basin'),
(2, 'GasFlow Interstate System', 'GasFlow Inc', 'Natural Gas', 'Texas Panhandle'),
(3, 'Eagle Ford Liquids', 'Frontier Energy', 'Natural Gas Liquids', 'South Texas'),
(4, 'Bakken Express', 'Northern Plains Pipelines', 'Crude Oil', 'North Dakota'),
(5, 'Colorado Gas Main', 'Rocky Mountain Gas', 'Natural Gas', 'Colorado'),
(6, 'TransAmerica Energy', 'TransAmerica Corp', 'Crude Oil', 'Gulf to Canada');

-- Routes
INSERT INTO pipelines_routes (id, system_id, name, geom, from_measure, to_measure, diameter_inches, material, grade, length_miles) VALUES
(1, 1, 'Permian Main Trunk', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -99.2433 31.2091, -95.3698 30.2672)', 4326), 0, 350, 30, 'Steel', 'X52', 350),
(2, 1, 'West Texas Branch', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -101.8821 29.5764)', 4326), 0, 55, 24, 'Steel', 'X42', 55),
(3, 1, 'New Mexico Extension', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -103.2258 28.8066)', 4326), 0, 85, 20, 'Steel', 'X42', 85),
(4, 2, 'OK-KS Gas Corridor', ST_GeomFromText('LINESTRING(-99.3033 35.4676, -97.5164 37.0842)', 4326), 0, 120, 36, 'Steel', 'X60', 120),
(5, 2, 'Panhandle Primary', ST_GeomFromText('LINESTRING(-101.5 35.5, -100.2 36.1)', 4326), 0, 95, 30, 'Steel', 'X60', 95),
(6, 3, 'Eagle Ford to Gulf', ST_GeomFromText('LINESTRING(-97.9 27.8, -94.5 29.3)', 4326), 0, 110, 16, 'Steel', 'X52', 110),
(7, 4, 'Bakken Central Gather', ST_GeomFromText('LINESTRING(-103.5 48.5, -102.1 48.8)', 4326), 0, 200, 28, 'Steel', 'X65', 200),
(8, 5, 'Colorado Front Range', ST_GeomFromText('LINESTRING(-105.0 40.0, -104.5 40.5)', 4326), 0, 75, 24, 'Steel', 'X60', 75),
(9, 6, 'Gulf-Canada Express', ST_GeomFromText('LINESTRING(-89.0 28.5, -90.0 30.0, -89.0 33.0, -87.0 36.0, -85.0 39.0, -84.0 43.0)', 4326), 0, 1300, 42, 'Steel', 'X70', 1300);

-- Segments for ALL Routes
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, wall_thickness_inches, material, grade, installation_year, operating_pressure_psi) VALUES
-- Route 1
(1, 0, 100, 30, 0.500, 'Steel', 'X52', 2005, 1200),
(1, 100, 250, 30, 0.500, 'Steel', 'X52', 2005, 1200),
(1, 250, 350, 30, 0.500, 'Steel', 'X52', 2005, 1200),
-- Route 2
(2, 0, 25, 24, 0.375, 'Steel', 'X42', 2010, 1000),
(2, 25, 55, 24, 0.375, 'Steel', 'X42', 2010, 1000),
-- Route 3
(3, 0, 40, 20, 0.312, 'Steel', 'X42', 2012, 1100),
(3, 40, 85, 20, 0.312, 'Steel', 'X42', 2012, 1100),
-- Route 4
(4, 0, 60, 36, 0.562, 'Steel', 'X60', 2008, 1440),
(4, 60, 120, 36, 0.562, 'Steel', 'X60', 2008, 1440),
-- Route 5
(5, 0, 45, 30, 0.500, 'Steel', 'X60', 2011, 1200),
(5, 45, 95, 30, 0.500, 'Steel', 'X60', 2011, 1200),
-- Route 6
(6, 0, 50, 16, 0.281, 'Steel', 'X52', 2014, 1100),
(6, 50, 110, 16, 0.281, 'Steel', 'X52', 2014, 1100),
-- Route 7
(7, 0, 100, 28, 0.438, 'Steel', 'X65', 2016, 1300),
(7, 100, 200, 28, 0.438, 'Steel', 'X65', 2016, 1300),
-- Route 8
(8, 0, 40, 24, 0.375, 'Steel', 'X60', 2013, 1150),
(8, 40, 75, 24, 0.375, 'Steel', 'X60', 2013, 1150),
-- Route 9 (Gulf-Canada)
(9, 0, 300, 42, 0.625, 'Steel', 'X70', 2012, 1200),
(9, 300, 600, 42, 0.625, 'Steel', 'X70', 2012, 1200),
(9, 600, 950, 42, 0.625, 'Steel', 'X70', 2012, 1200),
(9, 950, 1300, 42, 0.625, 'Steel', 'X70', 2012, 1200);

-- Stations (Representative samples)
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, geom, measure, capacity_value) VALUES
(1, 1, 'Midland Pump Station', 'pump', ST_GeomFromText('POINT(-102.0779 29.7604)', 4326), 0, 500000),
(6, 9, 'Gulf Inlet Pump', 'pump', ST_GeomFromText('POINT(-89.0 28.5)', 4326), 0, 800000);
