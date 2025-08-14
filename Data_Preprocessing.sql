--======================================================
-- PHASE 1: PROJECT SETUP & INITIAL VERIFICATION
--======================================================

-- 1.1 Table Creation
CREATE TABLE airlines (
    iata_code VARCHAR PRIMARY KEY,
    airline VARCHAR
);

CREATE TABLE airports (
    iata_code VARCHAR PRIMARY KEY,
    airport VARCHAR,
    city VARCHAR,
    state VARCHAR,
    country VARCHAR,
    latitude FLOAT,
    longitude FLOAT
);

CREATE TABLE flights (
    year INT,
    month INT,
    day INT,
    day_of_week INT,
    airline VARCHAR,
    flight_number INT,
    tail_number VARCHAR,
    origin_airport VARCHAR,
    destination_airport VARCHAR,
    scheduled_departure INT,
    departure_time INT,
    departure_delay INT,
    taxi_out INT,
    wheels_off INT,
    scheduled_time INT,
    elapsed_time INT,
    air_time INT,
    distance INT,
    wheels_on INT,
    taxi_in INT,
    scheduled_arrival INT,
    arrival_time INT,
    arrival_delay INT,
    diverted BOOLEAN,
    cancelled BOOLEAN,
    cancellation_reason VARCHAR,
    air_system_delay INT,
    security_delay INT,
    airline_delay INT,
    late_aircraft_delay INT,
    weather_delay INT
);

-- 1.2 Row Counts
SELECT COUNT(*) AS total_airlines FROM airlines;
SELECT COUNT(*) AS total_airports FROM airports;
SELECT COUNT(*) AS total_flights FROM flights;

-- 1.3 Sample Data Checks
SELECT * FROM airlines LIMIT 10;
SELECT * FROM airports LIMIT 10;
SELECT * FROM flights LIMIT 10;

--======================================================
-- PHASE 2: DATA CLEANING & PREPARATION
--======================================================

-- 2.1 Null Value Assessment
SELECT
    COUNT(*) FILTER (WHERE year IS NULL) AS year_nulls,
    COUNT(*) FILTER (WHERE month IS NULL) AS month_nulls,
    COUNT(*) FILTER (WHERE day IS NULL) AS day_nulls,
    COUNT(*) FILTER (WHERE day_of_week IS NULL) AS day_of_week_nulls,
    COUNT(*) FILTER (WHERE airline IS NULL) AS airline_nulls,
    COUNT(*) FILTER (WHERE flight_number IS NULL) AS flight_number_nulls,
    COUNT(*) FILTER (WHERE tail_number IS NULL) AS tail_number_nulls,
    COUNT(*) FILTER (WHERE origin_airport IS NULL) AS origin_airport_nulls,
    COUNT(*) FILTER (WHERE destination_airport IS NULL) AS destination_airport_nulls,
    COUNT(*) FILTER (WHERE scheduled_departure IS NULL) AS scheduled_departure_nulls,
    COUNT(*) FILTER (WHERE departure_time IS NULL) AS departure_time_nulls,
    COUNT(*) FILTER (WHERE departure_delay IS NULL) AS departure_delay_nulls,
    COUNT(*) FILTER (WHERE taxi_out IS NULL) AS taxi_out_nulls,
    COUNT(*) FILTER (WHERE wheels_off IS NULL) AS wheels_off_nulls,
    COUNT(*) FILTER (WHERE scheduled_time IS NULL) AS scheduled_time_nulls,
    COUNT(*) FILTER (WHERE elapsed_time IS NULL) AS elapsed_time_nulls,
    COUNT(*) FILTER (WHERE air_time IS NULL) AS air_time_nulls,
    COUNT(*) FILTER (WHERE distance IS NULL) AS distance_nulls,
    COUNT(*) FILTER (WHERE wheels_on IS NULL) AS wheels_on_nulls,
    COUNT(*) FILTER (WHERE taxi_in IS NULL) AS taxi_in_nulls,
    COUNT(*) FILTER (WHERE scheduled_arrival IS NULL) AS scheduled_arrival_nulls,
    COUNT(*) FILTER (WHERE arrival_time IS NULL) AS arrival_time_nulls,
    COUNT(*) FILTER (WHERE arrival_delay IS NULL) AS arrival_delay_nulls,
    COUNT(*) FILTER (WHERE diverted IS NULL) AS diverted_nulls,
    COUNT(*) FILTER (WHERE cancelled IS NULL) AS cancelled_nulls,
    COUNT(*) FILTER (WHERE cancellation_reason IS NULL) AS cancellation_reason_nulls,
    COUNT(*) FILTER (WHERE air_system_delay IS NULL) AS air_system_delay_nulls,
    COUNT(*) FILTER (WHERE security_delay IS NULL) AS security_delay_nulls,
    COUNT(*) FILTER (WHERE airline_delay IS NULL) AS airline_delay_nulls,
    COUNT(*) FILTER (WHERE late_aircraft_delay IS NULL) AS late_aircraft_delay_nulls,
    COUNT(*) FILTER (WHERE weather_delay IS NULL) AS weather_delay_nulls
FROM flights;

-- 2.2 Handle Missing Delay Values
UPDATE flights
SET
    departure_delay = CASE 
        WHEN cancelled = FALSE AND departure_delay IS NULL THEN 0
        ELSE departure_delay
    END,
    arrival_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND arrival_delay IS NULL THEN 0
        ELSE arrival_delay
    END,
    air_system_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND air_system_delay IS NULL THEN 0
        ELSE air_system_delay
    END,
    security_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND security_delay IS NULL THEN 0
        ELSE security_delay
    END,
    airline_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND airline_delay IS NULL THEN 0
        ELSE airline_delay
    END,
    late_aircraft_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND late_aircraft_delay IS NULL THEN 0
        ELSE late_aircraft_delay
    END,
    weather_delay = CASE 
        WHEN cancelled = FALSE AND diverted = FALSE AND weather_delay IS NULL THEN 0
        ELSE weather_delay
    END;

--======================================================
-- PHASE 3: DATE & TIME TRANSFORMATION
--======================================================

-- 3.1 Add datetime columns
ALTER TABLE flights
ADD COLUMN flight_date DATE,
ADD COLUMN scheduled_departure_ts TIMESTAMP,
ADD COLUMN departure_time_ts TIMESTAMP,
ADD COLUMN scheduled_arrival_ts TIMESTAMP,
ADD COLUMN arrival_time_ts TIMESTAMP,
ADD COLUMN wheels_off_ts TIMESTAMP,
ADD COLUMN wheels_on_ts TIMESTAMP;

-- 3.2 Populate datetime columns
UPDATE flights
SET flight_date = MAKE_DATE(year, month, day);

UPDATE flights
SET scheduled_departure_ts = TO_TIMESTAMP(
    LPAD(year::TEXT, 4, '0') || '-' ||
    LPAD(month::TEXT, 2, '0') || '-' ||
    LPAD(day::TEXT, 2, '0') || ' ' ||
    LPAD(scheduled_departure::TEXT, 4, '0'),
    'YYYY-MM-DD HH24MI'
)
WHERE scheduled_departure IS NOT NULL;

UPDATE flights
SET departure_time_ts =
    CASE
        WHEN departure_time = 2400 THEN
            TO_TIMESTAMP(TO_CHAR(MAKE_DATE(year, month, day) + INTERVAL '1 day', 'YYYY-MM-DD') || ' 0000', 'YYYY-MM-DD HH24MI')
        ELSE
            TO_TIMESTAMP(
                LPAD(year::TEXT, 4, '0') || '-' ||
                LPAD(month::TEXT, 2, '0') || '-' ||
                LPAD(day::TEXT, 2, '0') || ' ' ||
                LPAD(departure_time::TEXT, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    END
WHERE departure_time IS NOT NULL;

UPDATE flights
SET scheduled_arrival_ts =
    CASE
        WHEN scheduled_arrival = 2400 THEN
            TO_TIMESTAMP(TO_CHAR(MAKE_DATE(year, month, day) + INTERVAL '1 day', 'YYYY-MM-DD') || ' 0000', 'YYYY-MM-DD HH24MI')
        ELSE
            TO_TIMESTAMP(
                LPAD(year::TEXT, 4, '0') || '-' ||
                LPAD(month::TEXT, 2, '0') || '-' ||
                LPAD(day::TEXT, 2, '0') || ' ' ||
                LPAD(scheduled_arrival::TEXT, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    END
WHERE scheduled_arrival IS NOT NULL;

UPDATE flights
SET arrival_time_ts =
    CASE
        WHEN arrival_time = 2400 THEN
            TO_TIMESTAMP(TO_CHAR(MAKE_DATE(year, month, day) + INTERVAL '1 day', 'YYYY-MM-DD') || ' 0000', 'YYYY-MM-DD HH24MI')
        ELSE
            TO_TIMESTAMP(
                LPAD(year::TEXT, 4, '0') || '-' ||
                LPAD(month::TEXT, 2, '0') || '-' ||
                LPAD(day::TEXT, 2, '0') || ' ' ||
                LPAD(arrival_time::TEXT, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    END
WHERE arrival_time IS NOT NULL;

UPDATE flights
SET wheels_off_ts =
    CASE
        WHEN wheels_off = 2400 THEN
            TO_TIMESTAMP(TO_CHAR(MAKE_DATE(year, month, day) + INTERVAL '1 day', 'YYYY-MM-DD') || ' 0000', 'YYYY-MM-DD HH24MI')
        ELSE
            TO_TIMESTAMP(
                LPAD(year::TEXT, 4, '0') || '-' ||
                LPAD(month::TEXT, 2, '0') || '-' ||
                LPAD(day::TEXT, 2, '0') || ' ' ||
                LPAD(wheels_off::TEXT, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    END
WHERE wheels_off IS NOT NULL;

UPDATE flights
SET wheels_on_ts =
    CASE
        WHEN wheels_on = 2400 THEN
            TO_TIMESTAMP(TO_CHAR(MAKE_DATE(year, month, day) + INTERVAL '1 day', 'YYYY-MM-DD') || ' 0000', 'YYYY-MM-DD HH24MI')
        ELSE
            TO_TIMESTAMP(
                LPAD(year::TEXT, 4, '0') || '-' ||
                LPAD(month::TEXT, 2, '0') || '-' ||
                LPAD(day::TEXT, 2, '0') || ' ' ||
                LPAD(wheels_on::TEXT, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    END
WHERE wheels_on IS NOT NULL;

-- 3.3 Create Cancellation Reason Description
ALTER TABLE flights
ADD COLUMN cancellation_reason_desc VARCHAR;

UPDATE flights
SET cancellation_reason_desc = CASE cancellation_reason
    WHEN 'A' THEN 'Airline/Carrier'
    WHEN 'B' THEN 'Weather'
    WHEN 'C' THEN 'National Air System(Air Traffic Control)'
    WHEN 'D' THEN 'Security'
    ELSE 'Not Cancelled'
END;

--======================================================
-- PHASE 4: AIRPORT DATA CLEANING
--======================================================

-- 4.1 Identify invalid airport codes (numeric only)
SELECT DISTINCT origin_airport
FROM flights
WHERE origin_airport ~ '^[0-9]+$'
LIMIT 20;

SELECT month, COUNT(*) AS invalid_origin
FROM flights
WHERE origin_airport ~ '^[0-9]+$'
GROUP BY month
ORDER BY invalid_origin DESC;

-- 4.2 Set invalid airports to NULL
UPDATE flights
SET origin_airport = NULL
WHERE origin_airport ~ '^[0-9]+$';

UPDATE flights
SET destination_airport = NULL
WHERE destination_airport ~ '^[0-9]+$';

--======================================================
-- PHASE 5: RELATIONSHIPS & ANALYTICAL VIEW
--======================================================

-- 5.1 Add Foreign Keys
ALTER TABLE flights
ADD CONSTRAINT fk_airline FOREIGN KEY (airline) REFERENCES airlines(iata_code);

ALTER TABLE flights
ADD CONSTRAINT fk_origin FOREIGN KEY (origin_airport) REFERENCES airports(iata_code);

ALTER TABLE flights
ADD CONSTRAINT fk_destination FOREIGN KEY (destination_airport) REFERENCES airports(iata_code);

-- 5.2 Create Integrated Analytical View
CREATE OR REPLACE VIEW flight_analysis AS
SELECT
    f.*,
    al.airline AS airline_name,
    ao.airport AS origin_airport_name,
    ao.city AS origin_city,
    ao.state AS origin_state,
    ad.airport AS destination_airport_name,
    ad.city AS destination_city,
    ad.state AS destination_state
FROM flights f
LEFT JOIN airlines al ON f.airline = al.iata_code
LEFT JOIN airports ao ON f.origin_airport = ao.iata_code
LEFT JOIN airports ad ON f.destination_airport = ad.iata_code;

SELECT * FROM flight_analysis LIMIT 10;


