-- Pipeline System Seed Data (SQL)
-- This file contains realistic pipeline infrastructure data for development and testing
-- Usage: psql -U postgres -d pipeline_db -f database_seed.sql

-- Clear existing data (comment out if you want to preserve historical data)
DELETE FROM pipelines_inline_devices;
DELETE FROM pipelines_valves;
DELETE FROM pipelines_stations;
DELETE FROM pipelines_segments;
DELETE FROM pipelines_routes;
DELETE FROM pipelines_systems;

-- Insert Pipeline Systems
INSERT INTO pipelines_systems (name, operator_name, product, region) VALUES
('Midstream Crude Network', 'Energy Transport Corp', 'Crude Oil', 'Permian Basin'),
('GasFlow Interstate System', 'GasFlow Inc', 'Natural Gas', 'Texas Panhandle'),
('Eagle Ford Liquids', 'Frontier Energy', 'Natural Gas Liquids', 'South Texas'),
('Bakken Express', 'Northern Plains Pipelines', 'Crude Oil', 'North Dakota'),
('Colorado Gas Main', 'Rocky Mountain Gas', 'Natural Gas', 'Colorado');

-- Insert Routes
-- Midstream Crude Network routes
INSERT INTO pipelines_routes (system_id, name, product, capacity_bpd, diameter_inches, length_miles, geom) VALUES
(1, 'Permian Main Trunk', 'Crude Oil', 500000, 30, 350, ST_GeomFromText('LINESTRING(-102.0779 29.7604, -99.2433 31.2091, -95.3698 30.2672)', 4326)),
(1, 'West Texas Branch', 'Crude Oil', 250000, 24, 55, ST_GeomFromText('LINESTRING(-102.0779 29.7604, -101.8821 29.5764)', 4326)),
(1, 'New Mexico Extension', 'Crude Oil', 180000, 20, 85, ST_GeomFromText('LINESTRING(-102.0779 29.7604, -103.2258 28.8066)', 4326)),

-- GasFlow Interstate routes
(2, 'OK-KS Gas Corridor', 'Natural Gas', NULL, 36, 120, ST_GeomFromText('LINESTRING(-99.3033 35.4676, -97.5164 37.0842)', 4326)),
(2, 'Panhandle Primary', 'Natural Gas', NULL, 30, 95, ST_GeomFromText('LINESTRING(-101.5 35.5, -100.2 36.1)', 4326)),

-- Eagle Ford routes
(3, 'Eagle Ford to Gulf', 'Natural Gas Liquids', 150000, 16, 110, ST_GeomFromText('LINESTRING(-97.9 27.8, -94.5 29.3)', 4326)),

-- Bakken routes
(4, 'Bakken Central Gather', 'Crude Oil', 400000, 28, 200, ST_GeomFromText('LINESTRING(-103.5 48.5, -102.1 48.8)', 4326)),

-- Colorado routes
(5, 'Colorado Front Range', 'Natural Gas', NULL, 24, 75, ST_GeomFromText('LINESTRING(-105.0 40.0, -104.5 40.5)', 4326));

-- Insert Segments
INSERT INTO pipelines_segments (route_id, name, start_measure, end_measure, geom) VALUES
-- Permian Main Trunk segments
(1, 'Odessa to Midland', 0, 45, ST_GeomFromText('LINESTRING(-102.0779 29.7604, -101.9151 31.7500)', 4326)),
(1, 'Midland to Abilene', 45, 150, ST_GeomFromText('LINESTRING(-101.9151 31.7500, -99.7176 32.2477)', 4326)),
(1, 'Abilene to Fort Worth', 150, 280, ST_GeomFromText('LINESTRING(-99.7176 32.2477, -97.3331 32.7555)', 4326)),
(1, 'Fort Worth to Terminal', 280, 350, ST_GeomFromText('LINESTRING(-97.3331 32.7555, -95.3698 30.2672)', 4326)),

-- West Texas Branch
(2, 'Odessa Local Feeder', 0, 55, ST_GeomFromText('LINESTRING(-102.0779 29.7604, -101.8821 29.5764)', 4326)),

-- OK-KS Gas Corridor
(4, 'Oklahoma Section', 0, 70, ST_GeomFromText('LINESTRING(-99.3033 35.4676, -98.1000 36.2000)', 4326)),
(4, 'Kansas Section', 70, 120, ST_GeomFromText('LINESTRING(-98.1000 36.2000, -97.5164 37.0842)', 4326));

-- Insert Stations
INSERT INTO pipelines_stations (route_id, name, station_type, measure, operating_pressure_psi, capacity, geom) VALUES
-- Permian Main Trunk stations
(1, 'Odessa Pump Station', 'pump', 5, 850, 500000, ST_GeomFromText('POINT(-102.0779 29.8604)', 4326)),
(1, 'Midland Measurement', 'measurement', 50, 820, NULL, ST_GeomFromText('POINT(-101.9151 31.7500)', 4326)),
(1, 'Abilene Pump #1', 'pump', 160, 900, 500000, ST_GeomFromText('POINT(-99.7176 32.2477)', 4326)),
(1, 'Fort Worth Pressure Control', 'regulator', 290, 750, NULL, ST_GeomFromText('POINT(-97.3331 32.7555)', 4326)),
(1, 'Houston Terminal Reception', 'reception', 345, 50, NULL, ST_GeomFromText('POINT(-95.3698 30.2672)', 4326)),

-- West Texas Branch
(2, 'West Texas Pump', 'pump', 10, 900, 250000, ST_GeomFromText('POINT(-101.9800 29.6800)', 4326)),
(2, 'Andrews Delivery', 'delivery', 50, 100, NULL, ST_GeomFromText('POINT(-101.8821 29.5764)', 4326)),

-- OK-KS Gas Corridor
(4, 'Oklahoma City Compressor', 'compressor', 20, 950, 500, ST_GeomFromText('POINT(-97.5169 35.4676)', 4326)),
(4, 'Kansas Compressor Station', 'compressor', 100, 1050, 600, ST_GeomFromText('POINT(-97.8000 36.8000)', 4326)),

-- Eagle Ford
(6, 'Eagle Ford Pump Station', 'pump', 25, 880, 150000, ST_GeomFromText('POINT(-97.8000 27.9000)', 4326));

-- Insert Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, position, operating_pressure_psi, size_inches, geom) VALUES
-- Permian Main Trunk valves
(1, 'Odessa Block Valve 001', 'gate', 2, 'open', 850, 30, ST_GeomFromText('POINT(-102.0700 29.7650)', 4326)),
(1, 'Midland Check Valve 002', 'check', 48, 'open', 820, 30, ST_GeomFromText('POINT(-101.9000 31.7500)', 4326)),
(1, 'Abilene Block Valve 003', 'gate', 155, 'open', 900, 30, ST_GeomFromText('POINT(-99.7100 32.2500)', 4326)),
(1, 'Abilene Pressure Relief', 'relief', 165, 'open', 900, 4, ST_GeomFromText('POINT(-99.7200 32.2400)', 4326)),
(1, 'Fort Worth Block Valve 004', 'gate', 285, 'open', 750, 30, ST_GeomFromText('POINT(-97.3400 32.7500)', 4326)),
(1, 'Fort Worth Blowdown 001', 'blowdown', 292, 'closed', 0, 2, ST_GeomFromText('POINT(-97.3200 32.7600)', 4326)),
(1, 'Houston Terminal Block', 'gate', 348, 'open', 50, 36, ST_GeomFromText('POINT(-95.3600 30.2700)', 4326)),

-- West Texas Branch
(2, 'West Texas Block Valve', 'gate', 8, 'open', 900, 24, ST_GeomFromText('POINT(-101.9900 29.6700)', 4326)),
(2, 'Andrews Inlet Check', 'check', 52, 'open', 100, 24, ST_GeomFromText('POINT(-101.8700 29.5800)', 4326)),

-- OK-KS Gas Corridor
(4, 'Oklahoma Block Valve', 'gate', 15, 'open', 950, 36, ST_GeomFromText('POINT(-97.6000 35.3500)', 4326)),
(4, 'Kansas Inlet Check', 'check', 105, 'open', 1050, 36, ST_GeomFromText('POINT(-97.7500 36.9000)', 4326)),
(4, 'Kansas Relief Valve', 'relief', 108, 'open', 1050, 6, ST_GeomFromText('POINT(-97.7300 36.9100)', 4326));

-- Insert Inline Devices
INSERT INTO pipelines_inline_devices (route_id, name, device_type, measure, status, geom) VALUES
(1, 'Odessa Scraper Trap In', 'scraper_trap', 1, 'active', ST_GeomFromText('POINT(-102.0750 29.7620)', 4326)),
(1, 'Midland Flow Meter', 'flow_meter', 50, 'active', ST_GeomFromText('POINT(-101.9100 31.7510)', 4326)),
(1, 'Fort Worth Scraper Trap Out', 'scraper_trap', 349, 'active', ST_GeomFromText('POINT(-95.3700 30.2650)', 4326)),
(2, 'West Texas Flow Meter', 'flow_meter', 30, 'active', ST_GeomFromText('POINT(-101.9800 29.5800)', 4326));

-- Verify data
SELECT 'Systems' as entity, COUNT(*) as count FROM pipelines_systems
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
