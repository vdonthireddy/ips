-- Additional Key Devices for Intelligent Pipeline System
-- Adds more compressor stations, pump stations, and valves to the existing network

-- ============================================================================
-- 1. STATIONS (Compressors, Pumps, etc.)
-- ============================================================================

-- New Mexico Extension (Route 3) - Crude Oil
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, capacity_value, capacity_units, geom) VALUES
(1, 3, 'Hobbs Junction Pump Station', 'pump', 0, 150000, 'BPD', ST_GeomFromText('POINT(-102.0779 29.7604)', 4326)),
(1, 3, 'Carlsbad Delivery Terminal', 'delivery', 85, NULL, NULL, ST_GeomFromText('POINT(-103.2258 28.8066)', 4326));

-- Panhandle Primary (Route 5) - Natural Gas
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, capacity_value, capacity_units, operating_pressure_psi, geom) VALUES
(2, 5, 'Amarillo Compressor Station', 'compressor', 10, 1200, 'HP', 950, ST_GeomFromText('POINT(-101.4 35.55)', 4326)),
(2, 5, 'Pampa Regulator Station', 'regulator', 50, NULL, NULL, 800, ST_GeomFromText('POINT(-100.8 35.8)', 4326)),
(2, 5, 'Canadian River Compressor', 'compressor', 90, 1500, 'HP', 1100, ST_GeomFromText('POINT(-100.25 36.05)', 4326));

-- Bakken Central Gather (Route 7) - Crude Oil
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, capacity_value, capacity_units, geom) VALUES
(4, 7, 'Williston Gathering Hub', 'reception', 0, NULL, NULL, ST_GeomFromText('POINT(-103.5 48.5)', 4326)),
(4, 7, 'Tioga Pump Station', 'pump', 80, 200000, 'BPD', ST_GeomFromText('POINT(-102.9 48.65)', 4326)),
(4, 7, 'Minot Transfer Terminal', 'delivery', 200, NULL, NULL, ST_GeomFromText('POINT(-102.1 48.8)', 4326));

-- Colorado Front Range (Route 8) - Natural Gas
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, capacity_value, capacity_units, operating_pressure_psi, geom) VALUES
(5, 8, 'Denver City Gate', 'reception', 5, NULL, NULL, 1200, ST_GeomFromText('POINT(-104.95 40.05)', 4326)),
(5, 8, 'Greeley Compressor Station', 'compressor', 45, 800, 'HP', 1050, ST_GeomFromText('POINT(-104.7 40.3)', 4326)),
(5, 8, 'Fort Collins Delivery', 'delivery', 75, NULL, NULL, 400, ST_GeomFromText('POINT(-104.5 40.5)', 4326));

-- ============================================================================
-- 2. VALVES
-- ============================================================================

-- New Mexico Extension Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(3, 'Hobbs Block Valve', 'isolation', 5, 'open', 20, 1200, ST_GeomFromText('POINT(-102.15 29.7)', 4326)),
(3, 'NM State Line Check Valve', 'check', 42, 'open', 20, 1200, ST_GeomFromText('POINT(-102.65 29.25)', 4326)),
(3, 'Carlsbad Inlet Valve', 'isolation', 82, 'open', 20, 1200, ST_GeomFromText('POINT(-103.2 28.85)', 4326));

-- Panhandle Primary Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(5, 'Amarillo Main Block', 'isolation', 12, 'open', 30, 1440, ST_GeomFromText('POINT(-101.35 35.58)', 4326)),
(5, 'Gray County Blowdown', 'isolation', 45, 'closed', 4, 1440, ST_GeomFromText('POINT(-100.9 35.75)', 4326)),
(5, 'Pampa ESD Valve', 'isolation', 52, 'open', 30, 1440, ST_GeomFromText('POINT(-100.75 35.82)', 4326)),
(5, 'Canadian River Check', 'check', 88, 'open', 30, 1440, ST_GeomFromText('POINT(-100.3 36.0)', 4326));

-- Bakken Central Gather Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(7, 'Williston Basin Block 1', 'isolation', 15, 'open', 28, 1200, ST_GeomFromText('POINT(-103.4 48.52)', 4326)),
(7, 'Tioga Inlet Check', 'check', 78, 'open', 28, 1200, ST_GeomFromText('POINT(-102.95 48.63)', 4326)),
(7, 'Minot Terminal ESD', 'isolation', 195, 'open', 28, 1200, ST_GeomFromText('POINT(-102.15 48.78)', 4326));

-- Colorado Front Range Valves
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(8, 'Denver North Block', 'isolation', 8, 'open', 24, 1200, ST_GeomFromText('POINT(-104.9 40.1)', 4326)),
(8, 'Greeley Relief Valve', 'relief', 47, 'open', 6, 1100, ST_GeomFromText('POINT(-104.68 40.32)', 4326)),
(8, 'Fort Collins Gate Valve', 'isolation', 72, 'open', 24, 1200, ST_GeomFromText('POINT(-104.55 40.48)', 4326));

-- Additional Valves for Gulf-Canada Express (Route 9)
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(9, 'Mississippi River Crossing South', 'isolation', 450, 'open', 42, 1440, ST_GeomFromText('POINT(-89.5 31.5)', 4326)),
(9, 'Mississippi River Crossing North', 'isolation', 455, 'open', 42, 1440, ST_GeomFromText('POINT(-89.6 31.6)', 4326)),
(9, 'Ohio River Check Valve', 'check', 820, 'open', 42, 1440, ST_GeomFromText('POINT(-84.5 40.5)', 4326));

-- ============================================================================
-- 3. INLINE DEVICES (Meters, Scraper Traps)
-- ============================================================================

INSERT INTO pipelines_inline_devices (route_id, name, device_type, measure, geom) VALUES
(3, 'Hobbs Scraper Launch', 'scraper_trap', 1, ST_GeomFromText('POINT(-102.1 29.75)', 4326)),
(5, 'Amarillo Custody Meter', 'meter', 8, ST_GeomFromText('POINT(-101.42 35.53)', 4326)),
(7, 'Tioga Scraper Receiver', 'scraper_trap', 82, ST_GeomFromText('POINT(-102.88 48.66)', 4326)),
(8, 'Greeley Flow Computer', 'meter', 46, ST_GeomFromText('POINT(-104.69 40.31)', 4326));
