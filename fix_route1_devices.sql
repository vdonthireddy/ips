-- Fix for missing valves in Permian Main Trunk (Route 1)
-- These were previously skipped due to a syntax error in seed_fresh.sql

INSERT INTO pipelines_valves (route_id, name, valve_type, measure, normal_position, size_inches, rating_psi, geom) VALUES
(1, 'Odessa Block Valve 001', 'isolation', 2, 'open', 30, 1200, ST_GeomFromText('POINT(-102.0700 29.7650)', 4326)),
(1, 'Midland Check Valve 002', 'check', 48, 'open', 30, 1200, ST_GeomFromText('POINT(-101.9000 31.7500)', 4326)),
(1, 'Abilene Block Valve 003', 'isolation', 155, 'open', 30, 1200, ST_GeomFromText('POINT(-99.7100 32.2500)', 4326)),
(1, 'Abilene Pressure Relief', 'relief', 165, 'open', 4, 1000, ST_GeomFromText('POINT(-99.7200 32.2400)', 4326)),
(1, 'Fort Worth Block Valve 004', 'isolation', 285, 'open', 30, 1200, ST_GeomFromText('POINT(-97.3400 32.7500)', 4326)),
(1, 'Fort Worth Blowdown 001', 'isolation', 292, 'closed', 2, 300, ST_GeomFromText('POINT(-97.3200 32.7600)', 4326)),
(1, 'Houston Terminal Block', 'isolation', 348, 'open', 36, 1000, ST_GeomFromText('POINT(-95.3600 30.2700)', 4326));

-- Also fix those segments that had wrong column count
INSERT INTO pipelines_segments (route_id, from_measure, to_measure, diameter_inches, material, operating_pressure_psi, installation_year) VALUES
(9, 0, 300, 42, 'Steel', 1200, 2012),
(9, 300, 600, 42, 'Steel', 1200, 2012),
(9, 600, 950, 42, 'Steel', 1200, 2012),
(9, 950, 1300, 42, 'Steel', 1200, 2012);

-- Also add some inline devices for Route 1
INSERT INTO pipelines_inline_devices (route_id, name, device_type, measure, geom) VALUES
(1, 'Odessa Scraper Trap In', 'scraper_trap', 1, ST_GeomFromText('POINT(-102.0750 29.7620)', 4326)),
(1, 'Midland Flow Meter', 'meter', 50, ST_GeomFromText('POINT(-101.9100 31.7510)', 4326)),
(1, 'Fort Worth Scraper Trap Out', 'scraper_trap', 349, ST_GeomFromText('POINT(-95.3700 30.2650)', 4326));
