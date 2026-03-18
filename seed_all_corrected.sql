-- Consolidated and Corrected Seed Data for Intelligent Pipeline System
-- This file replaces the buggy seed_fresh.sql and adds all extra devices

-- STEP 1: Clear all data
TRUNCATE TABLE pipelines_inline_devices RESTART IDENTITY CASCADE;
TRUNCATE TABLE pipelines_valves RESTART IDENTITY CASCADE;
TRUNCATE TABLE pipelines_segments RESTART IDENTITY CASCADE;
TRUNCATE TABLE pipelines_stations RESTART IDENTITY CASCADE;
TRUNCATE TABLE pipelines_routes RESTART IDENTITY CASCADE;
TRUNCATE TABLE pipelines_systems RESTART IDENTITY CASCADE;

-- STEP 2: Pipeline Systems
INSERT INTO pipelines_systems (id, name, operator_name, product, region) VALUES
(1, 'Midstream Crude Network', 'Energy Transport Corp', 'Crude Oil', 'Permian Basin'),
(2, 'GasFlow Interstate System', 'GasFlow Inc', 'Natural Gas', 'Texas Panhandle'),
(3, 'Eagle Ford Liquids', 'Frontier Energy', 'Natural Gas Liquids', 'South Texas'),
(4, 'Bakken Express', 'Northern Plains Pipelines', 'Crude Oil', 'North Dakota'),
(5, 'Colorado Gas Main', 'Rocky Mountain Gas', 'Natural Gas', 'Colorado'),
(6, 'Gulf-Canada Express', 'TransAmerica Energy', 'Crude Oil', 'Gulf to Canada');

-- STEP 3: Routes
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

-- STEP 4: Segments
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, wall_thickness_inches, material, grade, installation_year, operating_pressure_psi) VALUES
(1, 0, 100, 30, 0.500, 'Steel', 'X52', 2005, 1200),
(1, 100, 250, 30, 0.500, 'Steel', 'X52', 2005, 1200),
(1, 250, 350, 30, 0.500, 'Steel', 'X52', 2005, 1200),
(2, 0, 55, 24, 0.375, 'Steel', 'X42', 2010, 1000),
(4, 0, 120, 36, 0.562, 'Steel', 'X60', 2008, 1440),
(9, 0, 300, 42, 0.500, 'Steel', 'X70', 2012, 1200),
(9, 300, 600, 42, 0.500, 'Steel', 'X70', 2012, 1200),
(9, 600, 1300, 42, 0.500, 'Steel', 'X70', 2012, 1200);

-- STEP 5: Stations
INSERT INTO pipelines_stations (system_id, route_id, name, station_type, measure, capacity_value, capacity_units, geom) VALUES
(1, 1, 'Odessa Pump Station', 'pump', 5, 500000, 'BPD', ST_GeomFromText('POINT(-102.0779 29.8604)', 4326)),
(1, 1, 'Midland Measurement', 'measurement', 50, NULL, NULL, ST_GeomFromText('POINT(-101.9151 31.7500)', 4326)),
(1, 1, 'Abilene Pump #1', 'pump', 160, 500000, 'BPD', ST_GeomFromText('POINT(-99.7176 32.2477)', 4326)),
(1, 1, 'Fort Worth Pressure Control', 'regulator', 290, NULL, NULL, ST_GeomFromText('POINT(-97.3331 32.7555)', 4326)),
(1, 1, 'Houston Terminal Reception', 'reception', 345, NULL, NULL, ST_GeomFromText('POINT(-95.3698 30.2672)', 4326)),
(1, 2, 'West Texas Pump', 'pump', 10, 250000, 'BPD', ST_GeomFromText('POINT(-101.9800 29.6800)', 4326)),
(1, 2, 'Andrews Delivery', 'delivery', 50, NULL, NULL, ST_GeomFromText('POINT(-101.8821 29.5764)', 4326)),
(2, 4, 'Oklahoma City Compressor', 'compressor', 20, 500, 'HP', ST_GeomFromText('POINT(-97.5169 35.4676)', 4326)),
(2, 4, 'Kansas Compressor Station', 'compressor', 100, 600, 'HP', ST_GeomFromText('POINT(-97.8000 36.8000)', 4326)),
(6, 9, 'Gulf Inlet Pump', 'pump', 0, 800000, 'BPD', ST_GeomFromText('POINT(-89.0 28.5)', 4326)),
(6, 9, 'Memphis Meter Station', 'measurement', 300, NULL, NULL, ST_GeomFromText('POINT(-90.0 35.1)', 4326)),
(6, 9, 'Chicago Compressor', 'compressor', 750, 800, 'HP', ST_GeomFromText('POINT(-87.6 41.8)', 4326)),
(6, 9, 'Toronto Delivery Terminal', 'delivery', 1300, NULL, NULL, ST_GeomFromText('POINT(-79.4 43.7)', 4326)),
(2, 5, 'Amarillo Compressor Station', 'compressor', 10, 1200, 'HP', ST_GeomFromText('POINT(-101.4 35.55)', 4326)),
(4, 7, 'Tioga Pump Station', 'pump', 80, 200000, 'BPD', ST_GeomFromText('POINT(-102.9 48.65)', 4326)),
(5, 8, 'Greeley Compressor Station', 'compressor', 45, 800, 'HP', ST_GeomFromText('POINT(-104.7 40.3)', 4326));

-- STEP 6: Valves (The missing pieces)
INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
-- Route 1 (Permian Main Trunk)
(1, 'Odessa Block Valve 001', 'isolation', 2, 'open', 30, 1200, ST_GeomFromText('POINT(-102.0700 29.7650)', 4326)),
(1, 'Midland Check Valve 002', 'check', 48, 'open', 30, 1200, ST_GeomFromText('POINT(-101.9000 31.7500)', 4326)),
(1, 'Abilene Block Valve 003', 'isolation', 155, 'open', 30, 1200, ST_GeomFromText('POINT(-99.7100 32.2500)', 4326)),
(1, 'Abilene Pressure Relief', 'relief', 165, 'open', 4, 1000, ST_GeomFromText('POINT(-99.7200 32.2400)', 4326)),
(1, 'Fort Worth Block Valve 004', 'isolation', 285, 'open', 30, 1200, ST_GeomFromText('POINT(-97.3400 32.7500)', 4326)),
(1, 'Fort Worth Blowdown 001', 'isolation', 292, 'closed', 2, 300, ST_GeomFromText('POINT(-97.3200 32.7600)', 4326)),
(1, 'Houston Terminal Block', 'isolation', 348, 'open', 36, 1000, ST_GeomFromText('POINT(-95.3600 30.2700)', 4326)),

-- Route 2 (West Texas Branch)
(2, 'West Texas Block Valve', 'isolation', 8, 'open', 24, 1200, ST_GeomFromText('POINT(-101.9900 29.6700)', 4326)),
(2, 'Andrews Inlet Check', 'check', 52, 'open', 24, 1000, ST_GeomFromText('POINT(-101.8700 29.5800)', 4326)),

-- Route 4 (OK-KS Corridor)
(4, 'Oklahoma Block Valve', 'isolation', 15, 'open', 36, 1500, ST_GeomFromText('POINT(-97.6000 35.3500)', 4326)),
(4, 'Kansas Inlet Check', 'check', 105, 'open', 36, 1500, ST_GeomFromText('POINT(-97.7500 36.9000)', 4326)),
(4, 'Kansas Relief Valve', 'relief', 108, 'open', 6, 1200, ST_GeomFromText('POINT(-97.7300 36.9100)', 4326)),

-- Route 9 (Gulf-Canada)
(9, 'Gulf Inlet Block Valve', 'isolation', 5, 'open', 42, 1400, ST_GeomFromText('POINT(-89.0 28.5)', 4326)),
(9, 'Mississippi River Crossing South', 'isolation', 450, 'open', 42, 1440, ST_GeomFromText('POINT(-89.5 31.5)', 4326)),
(9, 'Mississippi River Crossing North', 'isolation', 455, 'open', 42, 1440, ST_GeomFromText('POINT(-89.6 31.6)', 4326)),
(9, 'Ohio River Check Valve', 'check', 820, 'open', 42, 1440, ST_GeomFromText('POINT(-84.5 40.5)', 4326)),
(9, 'Toronto Delivery Block', 'isolation', 1295, 'open', 42, 1400, ST_GeomFromText('POINT(-79.4 43.7)', 4326)),

-- Route 5 (Panhandle)
(5, 'Amarillo Main Block', 'isolation', 12, 'open', 30, 1440, ST_GeomFromText('POINT(-101.35 35.58)', 4326)),
(5, 'Pampa ESD Valve', 'isolation', 52, 'open', 30, 1440, ST_GeomFromText('POINT(-100.75 35.82)', 4326)),

-- Route 7 (Bakken)
(7, 'Williston Basin Block 1', 'isolation', 15, 'open', 28, 1200, ST_GeomFromText('POINT(-103.4 48.52)', 4326)),
(7, 'Minot Terminal ESD', 'isolation', 195, 'open', 28, 1200, ST_GeomFromText('POINT(-102.15 48.78)', 4326)),

-- Route 8 (Colorado)
(8, 'Denver North Block', 'isolation', 8, 'open', 24, 1200, ST_GeomFromText('POINT(-104.9 40.1)', 4326)),
(8, 'Fort Collins Gate Valve', 'isolation', 72, 'open', 24, 1200, ST_GeomFromText('POINT(-104.55 40.48)', 4326));

-- STEP 7: Inline Devices
INSERT INTO pipelines_inline_devices (route_id, name, device_type, measure, geom) VALUES
(1, 'Odessa Scraper Trap In', 'scraper_trap', 1, ST_GeomFromText('POINT(-102.0750 29.7620)', 4326)),
(1, 'Midland Flow Meter', 'meter', 50, ST_GeomFromText('POINT(-101.9100 31.7510)', 4326)),
(1, 'Fort Worth Scraper Trap Out', 'scraper_trap', 349, ST_GeomFromText('POINT(-95.3700 30.2650)', 4326)),
(3, 'Hobbs Scraper Launch', 'scraper_trap', 1, ST_GeomFromText('POINT(-102.1 29.75)', 4326)),
(5, 'Amarillo Custody Meter', 'meter', 8, ST_GeomFromText('POINT(-101.42 35.53)', 4326)),
(7, 'Tioga Scraper Receiver', 'scraper_trap', 82, ST_GeomFromText('POINT(-102.88 48.66)', 4326));

-- STEP 8: Final Check
SELECT '========== DATA RECOVERY SUMMARY ==========' as info;
SELECT 'Valves' as entity, COUNT(*) as count FROM pipelines_valves
UNION ALL
SELECT 'Stations', COUNT(*) FROM pipelines_stations
UNION ALL
SELECT 'Devices', COUNT(*) FROM pipelines_inline_devices
ORDER BY count DESC;
