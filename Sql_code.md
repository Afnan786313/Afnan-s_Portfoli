# Cyclistic Data Cleaning and Analysis

This SQL script is used to clean, transform, and analyze Cyclistic bike-sharing data for Q1 2019 and Q1 2020. It creates tables for standardized data, performs summary statistics, and generates trend analysis by hour and day of the week.

---

## 1. Create Table for 2019 Q1 Data

```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.0k_2019_Q1` AS
SELECT 
    CAST(trip_id AS STRING) AS ride_id,                -- Convert trip_id to STRING and rename as ride_id
    CAST(bikeid AS STRING) AS rideable_type,           -- Convert bikeid to STRING and rename as rideable_type
    start_time AS started_at,                          -- Rename columns as needed
    end_time AS ended_at,
    from_station_name AS start_station_name,
    from_station_id AS start_station_id,
    to_station_name AS end_station_name,
    to_station_id AS end_station_id,
    usertype AS member_casual
FROM flowing-gasket-440008-g2.Cyclistic_Data_2019_20.Divvy_Trips_2019_Q1;
```

## 2. Create Table for 2020 Q1 Data

```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.0k_2020_Q1` AS
SELECT 
    ride_id,                   
    rideable_type,
    started_at,
    ended_at,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    member_casual
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.Divvy_Trips_2020_Q1`;
```
 
## 3. Combine 2019 and 2020 Data
```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_ok` AS
SELECT * FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.0k_2019_Q1`
UNION ALL
SELECT * FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.0k_2020_Q1`;
```

## 4. Clean Combined Data (Remove NULL Values)
```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_cleaned` AS
SELECT *
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_ok`
WHERE 
    ride_id IS NOT NULL
    AND rideable_type IS NOT NULL
    AND started_at IS NOT NULL
    AND ended_at IS NOT NULL
    AND start_station_name IS NOT NULL
    AND start_station_id IS NOT NULL
    AND end_station_name IS NOT NULL
    AND end_station_id IS NOT NULL
    AND member_casual IS NOT NULL;
```

## 5. Standardize Member Type Values
```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized` AS
SELECT 
    ride_id,
    rideable_type,
    started_at,
    ended_at,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    CASE 
        WHEN LOWER(member_casual) IN ('subscriber', 'member') THEN 'member'
        WHEN LOWER(member_casual) IN ('customer', 'casual') THEN 'casual'
        ELSE member_casual
    END AS member_casual
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_ok`;
```

## 6. Count Total Rows
```sql
SELECT COUNT(*) AS total_rows
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`;
```

## 7. Count Distinct Values for Each Column
```sql
SELECT 
    COUNT(DISTINCT ride_id) AS distinct_ride_ids,
    COUNT(DISTINCT rideable_type) AS distinct_rideable_types,
    COUNT(DISTINCT start_station_name) AS distinct_start_stations,
    COUNT(DISTINCT end_station_name) AS distinct_end_stations,
    COUNT(DISTINCT member_casual) AS distinct_member_casual
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`;
```

## 8. Calculate Ride Length Statistics
```sql
SELECT 
    MAX(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS max_ride_length_seconds,
    MIN(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS min_ride_length_seconds,
    AVG(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS avg_ride_length_seconds
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`;
```

## 9. Summary Statistics by Member Type
```sql
SELECT 
    member_casual,
    COUNT(ride_id) AS total_rides,
    AVG(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS avg_ride_length_seconds
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`
GROUP BY member_casual;
```

## 10. Summary Statistics by Day of the Week
```sql
SELECT 
    FORMAT_TIMESTAMP('%A', started_at) AS day_of_week,
    member_casual,
    COUNT(ride_id) AS total_rides,
    AVG(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS avg_ride_length_seconds
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`
GROUP BY day_of_week, member_casual
ORDER BY member_casual,
    CASE day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;
```

## 11. Ride Trends by Hour
```sql
CREATE OR REPLACE TABLE `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.ride_trends_by_hour` AS
SELECT 
    EXTRACT(HOUR FROM started_at) AS hour_of_day,
    member_casual,
    COUNT(ride_id) AS total_rides,
    AVG(TIMESTAMP_DIFF(ended_at, started_at, SECOND)) AS avg_ride_length_seconds
FROM `flowing-gasket-440008-g2.Cyclistic_Data_2019_20.combined_trips_standardized`
GROUP BY hour_of_day, member_casual
ORDER BY hour_of_day;
```
