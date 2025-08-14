-- =======================================
-- FLIGHT DATA EDA & KPI ANALYSIS
-- =======================================

-- =======================================
-- 1️⃣ FLIGHT VOLUME & CANCELLATIONS
-- =======================================

-- 1.1 Overall Flight Volume & Cancellations
SELECT
    COUNT(*) AS total_flights,
    SUM(CASE WHEN cancelled THEN 1 ELSE 0 END) AS total_cancelled,
    SUM(CASE WHEN diverted THEN 1 ELSE 0 END) AS total_diverted
FROM flights;

-- 1.2 Cancellations by Reason
SELECT
    cancellation_reason_desc,
    COUNT(*) AS total_cancellations,
    ROUND(100.0 * COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM flights
WHERE cancelled = TRUE
GROUP BY cancellation_reason_desc
ORDER BY total_cancellations DESC;

-- 1.3 Basic Delay Statistics
SELECT
    AVG(departure_delay) AS avg_dep_delay,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY departure_delay) AS median_dep_delay,
    MAX(departure_delay) AS max_dep_delay,
    AVG(arrival_delay) AS avg_arr_delay,
    MAX(arrival_delay) AS max_arr_delay
FROM flights
WHERE cancelled = FALSE;


-- =======================================
-- 2️⃣ OVERALL KPIs & DELAY CONTRIBUTION
-- =======================================

SELECT
    -- On-Time Performance (<= 15 min)
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent,
    -- Average Delays
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    -- Cancellation Rate
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent,
    -- Delay Type Contribution
    ROUND(100.0 * SUM(airline_delay)::NUMERIC / NULLIF(SUM(
        airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay
    ),0), 2) AS airline_delay_pct,
    ROUND(100.0 * SUM(weather_delay)::NUMERIC / NULLIF(SUM(
        airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay
    ),0), 2) AS weather_delay_pct,
    ROUND(100.0 * SUM(air_system_delay)::NUMERIC / NULLIF(SUM(
        airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay
    ),0), 2) AS air_system_delay_pct,
    ROUND(100.0 * SUM(security_delay)::NUMERIC / NULLIF(SUM(
        airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay
    ),0), 2) AS security_delay_pct,
    ROUND(100.0 * SUM(late_aircraft_delay)::NUMERIC / NULLIF(SUM(
        airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay
    ),0), 2) AS late_aircraft_delay_pct
FROM flights
WHERE cancelled = FALSE;


-- =======================================
-- 3️⃣ KPI AGGREGATIONS BY DIMENSIONS
-- =======================================

-- 3.1 KPIs by Airline
SELECT
    airline_name,
    COUNT(*) AS total_flights,
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent
FROM flight_analysis
GROUP BY airline_name
ORDER BY otp_rate_percent DESC;

-- 3.2 KPIs by Origin Airport (Ascending by Avg Departure Delay)
SELECT
    origin_airport_name,
    origin_city,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent,
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent
FROM flight_analysis
WHERE origin_airport_name IS NOT NULL
GROUP BY origin_airport_name, origin_city
ORDER BY avg_departure_delay ASC
LIMIT 20;

-- 3.3 KPIs by Destination Airport (Ascending by Avg Arrival Delay)
SELECT
    destination_airport_name,
    destination_city,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent,
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent
FROM flight_analysis
WHERE destination_airport_name IS NOT NULL
GROUP BY destination_airport_name, destination_city
ORDER BY avg_arrival_delay ASC
LIMIT 20;

-- 3.4 KPIs by Month
SELECT
    month,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent,
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent
FROM flights
GROUP BY month
ORDER BY month ASC;

-- 3.5 KPIs by Day of Week
SELECT
    day_of_week,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_percent,
    ROUND(100.0 * SUM(CASE WHEN arrival_delay <= 15 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*), 2) AS otp_rate_percent
FROM flights
GROUP BY day_of_week
ORDER BY day_of_week ASC;


-- =======================================
-- 4️⃣ DELAY & CANCELLATION INSIGHTS
-- =======================================

-- 4.1 Top 10 Airlines by Avg Arrival Delay
SELECT
    airline_name,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*), 2) AS cancel_rate_pct
FROM flight_analysis
GROUP BY airline_name
ORDER BY avg_arrival_delay DESC
LIMIT 10;

-- 4.2 Top 10 Airports by Avg Arrival Delay
SELECT
    origin_airport_name,
    origin_city,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay
FROM flight_analysis
GROUP BY origin_airport_name, origin_city
ORDER BY avg_arrival_delay DESC
LIMIT 10;

-- 4.3 Delay Reason Contribution by Month
SELECT
    month,
    ROUND(AVG(airline_delay), 2) AS avg_airline_delay,
    ROUND(AVG(weather_delay), 2) AS avg_weather_delay,
    ROUND(AVG(air_system_delay), 2) AS avg_system_delay,
    ROUND(AVG(security_delay), 2) AS avg_security_delay,
    ROUND(AVG(late_aircraft_delay), 2) AS avg_late_aircraft_delay
FROM flights
WHERE cancelled = FALSE
GROUP BY month
ORDER BY month;


-- =======================================
-- 5️⃣ ROUTE & NETWORK ANALYSIS
-- =======================================

-- 5.1 Busiest Routes (Exclude NULL)
SELECT
    origin_airport_name || ' → ' || destination_airport_name AS route,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay
FROM flight_analysis
WHERE origin_airport_name IS NOT NULL
  AND destination_airport_name IS NOT NULL
GROUP BY origin_airport_name, destination_airport_name
ORDER BY total_flights DESC
LIMIT 15;

-- 5.2 Worst Routes by Avg Arrival Delay (Min 100 Flights)
SELECT
    origin_airport_name || ' → ' || destination_airport_name AS route,
    COUNT(*) AS total_flights,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay
FROM flight_analysis
WHERE cancelled = FALSE
  AND origin_airport_name IS NOT NULL
  AND destination_airport_name IS NOT NULL
GROUP BY origin_airport_name, destination_airport_name
HAVING COUNT(*) > 100
ORDER BY avg_arrival_delay DESC
LIMIT 15;

-- 5.3 Routes with Highest Cancellation Rate
SELECT
    origin_airport_name || ' → ' || destination_airport_name AS route,
    COUNT(*) AS total_flights,
    ROUND(100.0 * SUM(cancelled::int) / COUNT(*),2) AS cancel_rate_pct
FROM flight_analysis
WHERE origin_airport_name IS NOT NULL
  AND destination_airport_name IS NOT NULL
GROUP BY origin_airport_name, destination_airport_name
HAVING COUNT(*) > 100
ORDER BY cancel_rate_pct DESC
LIMIT 15;

-- 5.4 Routes with Most Diversions
SELECT
    origin_airport_name || ' → ' || destination_airport_name AS route,
    COUNT(*) AS total_flights,
    SUM(diverted::int) AS total_diversions,
    ROUND(100.0 * SUM(diverted::int) / COUNT(*),2) AS diversion_rate_pct
FROM flight_analysis
WHERE origin_airport_name IS NOT NULL
  AND destination_airport_name IS NOT NULL
GROUP BY origin_airport_name, destination_airport_name
HAVING COUNT(*) > 100
ORDER BY diversion_rate_pct DESC
LIMIT 15;


-- =======================================
-- 6️⃣ SAFETY & IRREGULARITY ANALYSIS
-- =======================================

-- 6.1 Flights with Extreme Delays (>300 min)
SELECT *
FROM flight_analysis
WHERE arrival_delay > 300
ORDER BY arrival_delay DESC
LIMIT 20;

-- 6.2 Diversion Hotspots (Top 10 Airports)
SELECT
    destination_airport_name,
    SUM(diverted::int) AS total_diversions,
    ROUND(100.0 * SUM(diverted::int)/COUNT(*),2) AS diversion_rate_pct
FROM flight_analysis
GROUP BY destination_airport_name
ORDER BY diversion_rate_pct DESC
LIMIT 10;

-- 6.3 Diversion Rate by Airline
SELECT
    airline_name,
    ROUND(100.0 * SUM(diverted::int)::NUMERIC / COUNT(*), 2) AS diversion_rate_pct
FROM flight_analysis
GROUP BY airline_name
ORDER BY diversion_rate_pct DESC;


-- =======================================
-- 7️⃣ OPERATIONAL EFFICIENCY
-- =======================================

-- Airlines with Most Consistent Performance
SELECT
    airline_name,
    ROUND(AVG(arrival_delay),2) AS avg_delay,
    ROUND(STDDEV(arrival_delay),2) AS delay_variability
FROM flight_analysis
WHERE cancelled = FALSE
GROUP BY airline_name
ORDER BY delay_variability ASC
LIMIT 10;
