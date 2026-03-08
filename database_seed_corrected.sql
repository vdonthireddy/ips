-- Pipeline System Seed Data (SQL) - Corrected for actual schema
-- This file contains realistic pipeline infrastructure data for development and testing
-- Usage: docker exec pipeline-db psql -U postgres -d pipeline_gis -f /tmp/database_seed_corrected.sql

-- Insert Pipeline Systems (these must exist before routes)
INSERT INTO pipelines_systems (name, operator_name, product, region) VALUES
('Midstream Crude Network', 'Energy Transport Corp', 'Crude Oil', 'Permian Basin'),
('GasFlow Interstate System', 'GasFlow Inc', 'Natural Gas', 'Texas Panhandle'),
('Eagle Ford Liquids', 'Frontier Energy', 'Natural Gas Liquids', 'South Texas'),
('Bakken Express', 'Northern Plains Pipelines', 'Crude Oil', 'North Dakota'),
('Colorado Gas Main', 'Rocky Mountain Gas', 'Natural Gas', 'Colorado');

-- Insert Routes
INSERT INTO pipelines_routes (system_id, name, geom, from_measure, to_measure, diameter_inches, material, length_miles) VALUES
-- Midstream Crude Network routes
(8, 'Permian Main Trunk', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -99.2433 31.2091, -95.3698 30.2672)', 4326), 0, 350, 30, 'Steel', 350),
(8, 'West Texas Branch', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -101.8821 29.5764)', 4326), 0, 55, 24, 'Steel', 55),
(8, 'New Mexico Extension', ST_GeomFromText('LINESTRING(-102.0779 29.7604, -103.2258 28.8066)', 4326), 0, 85, 20, 'Steel', 85),

-- GasFlow Interstate routes
(9, 'OK-KS Gas Corridor', ST_GeomFromText('LINESTRING(-99.3033 35.4676, -97.5164 37.0842)', 4326), 0, 120, 36, 'Steel', 120),
(9, 'Panhandle Primary', ST_GeomFromText('LINESTRING(-101.5 35.5, -100.2 36.1)', 4326), 0, 95, 30, 'Steel', 95),

-- Eagle Ford routes
(10, 'Eagle Ford to Gulf', ST_GeomFromText('LINESTRING(-97.9 27.8, -94.5 29.3)', 4326), 0, 110, 16, 'Steel', 110),

-- Bakken routes
(11, 'Bakken Central Gather', ST_GeomFromText('LINESTRING(-103.5 48.5, -102.1 48.8)', 4326), 0, 200, 28, 'Steel', 200),

-- Colorado routes
(12, 'Colorado Front Range', ST_GeomFromText('LINESTRING(-105.0 40.0, -104.5 40.5)', 4326), 0, 75, 24, 'Steel', 75);

-- Insert Pipe Segments
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, material, operating_pressure_psi, installation_year) VALUES
-- Permian Main Trunk segments
(1, 0, 45, 30, 'Steel', 850, 2015),
(1, 45, 150, 30, 'Steel', 820, 2015),
(1, 150, 280, 30, 'Steel', 900, 2015),
(1, 280, 350, 36, 'Steel', 750, 2018),

-- West Texas Branch
(2, 0, 55, 24, 'Steel', 900, 2016),

-- OK-KS Gas Corridor
(4, 0, 70, 36, 'Steel', 950, 2014),
(4, 70, 120, 36, 'Steel', 1050, 2014);

-- Insert Stations
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, operating_pressure_psi, capacity_value, capacity_units, geom) VALUES
-- Permian Main Trunk stations
(1, 1, 'Odessa Pump Station', 'pump', 5, 850, 500000, 'BPD', ST_GeomFromText('POINT(-102.0779 29.8604)', 4326)),
(1, 1, 'Midland Measurement', 'measurement', 50, 820, NULL, NULL, ST_GeomFromText('POINT(-101.9151 31.7500)', 4326)),
(1, 1, 'Abilene Pump #1', 'pump', 160, 900, 500000, 'BPD', ST_GeomFromText('POINT(-99.7176 32.2477)', 4326)),
(1, 1, 'Fort Worth Pressure Control', 'regulator', 290, 750, NULL, NULL, ST_GeomFromText('POINT(-97.3331 32.7555)', 4326)),
(1, 1, 'Houston Terminal Reception', 'reception', 345, 50, NULL, NULL, ST_GeomFromText('POINT(-95.3698 30.2672)', 4326)),

-- West Texas Branch
(1, 2, 'West Texas Pump', 'pump', 10, 900, 250000, 'BPD', ST_GeomFromText('POINT(-101.9800 29.6800)', 4326)),
(1, 2, 'Andrews Delivery', 'delivery', 50, 100, NULL, NULL, ST_GeomFromText('POINT(-101.8821 29.5764)', 4326)),

-- OK-KS Gas Corridor
(2, 4, 'Oklahoma City Compressor', 'compressor', 20, 950, 500, 'HP', ST_GeomFromText('POINT(-97.5169 35.4676)', 4326)),
(2, 4, 'Kansas Compressor Station', 'compressor', 100, 1050, 600, 'HP', ST_GeomFromText('POINT(-97.8000 36.8000)', 4326)),

-- Eagle Ford
(3, 6, 'Eagle Ford Pump Station', 'pump', 25, 880, 150000, 'BPD', ST_GeomFromText('POINT(-97.8000 27.9000)', 4326));

-- Insert Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
-- Permian Main Trunk valves
(1, 'Odessa Block Valve 001', 'isolation', 2, 'open', 30, 1200, ST_GeomFromText('POINT(-102.0700 29.7650)', 4326)),
(1, 'Midland Check Valve 002', 'check', 48, 'open', 30, 1200, ST_GeomFromText('POINT(-101.9000 31.7500)', 4326)),
(1, 'Abilene Block Valve 003', 'isolation', 155, 'open', 30, 1200, ST_GeomFromText('POINT(-99.7100 32.2500)', 4326)),
(1, 'Abilene Pressure Relief', 'relief', 165, 'open', 4, 1000, ST_GeomFromText('POINT(-99.7200 32.2400)', 4326)),
(1, 'Fort Worth Block Valve 004', 'isolation', 285, 'open', 30, 1200, ST_GeomFromText('POINT(-97.3400 32.7500)', 4326)),
(1, 'Fort Worth Blowdown 001', 'isolation', 292, 'closed', 2, 300, ST_GeomFromText('POINT(-97.3200 32.7600)', 4326)),
(1, 'Houston Terminal Block', 'isolation', 348, 'open', 36, 1000, ST_GeomFromText('POINT(-95.3600 30.2700)', 4326)),

-- West Texas Branch
(2, 'West Texas Block Valve', 'isolation', 8, 'open', 24, 1200, ST_GeomFromText('POINT(-101.9900 29.6700)', 4326)),
(2, 'Andrews Inlet Check', 'check', 52, 'open', 24, 1000, ST_GeomFromText('POINT(-101.8700 29.5800)', 4326)),

-- OK-KS Gas Corridor
(4, 'Oklahoma Block Valve', 'isolation', 15, 'open', 36, 1500, ST_GeomFromText('POINT(-97.6000 35.3500)', 4326)),
(4, 'Kansas Inlet Check', 'check', 105, 'open', 36, 1500, ST_GeomFromText('POINT(-97.7500 36.9000)', 4326)),
(4, 'Kansas Relief Valve', 'relief', 108, 'open', 6, 1200, ST_GeomFromText('POINT(-97.7300 36.9100)', 4326));

-- Insert Inline Devices
INSERT INTO pipelines_inline_devices (route_id, name, device_type, measure, geom) VALUES
(1, 'Odessa Scraper Trap In', 'scraper_trap', 1, ST_GeomFromText('POINT(-102.0750 29.7620)', 4326)),
(1, 'Midland Flow Meter', 'meter', 50, ST_GeomFromText('POINT(-101.9100 31.7510)', 4326)),
(1, 'Fort Worth Scraper Trap Out', 'scraper_trap', 349, ST_GeomFromText('POINT(-95.3700 30.2650)', 4326)),
(2, 'West Texas Flow Meter', 'meter', 30, ST_GeomFromText('POINT(-101.9800 29.5800)', 4326));

-- Verify data
SELECT 'Data Upload Summary' as status;
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

-- Show system overview
SELECT '--- System Overview ---' as info;
SELECT s.name, s.operator_name, s.product, s.region, COUNT(r.id) as route_count
FROM pipelines_systems s
LEFT JOIN pipelines_routes r ON r.system_id = s.id
GROUP BY s.id, s.name, s.operator_name, s.product, s.region
ORDER BY s.name;
