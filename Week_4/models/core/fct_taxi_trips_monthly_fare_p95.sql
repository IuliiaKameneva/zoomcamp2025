{{ config(materialized='table') }}

WITH filter_fact_trips AS (
    SELECT 
        service_type,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(MONTH FROM pickup_datetime) AS month,
        fare_amount
    FROM {{ ref('fact_trips') }}
    WHERE 
        fare_amount > 0 
        AND trip_distance > 0 
        AND payment_type_description IN ('Cash', 'Credit card')
),

trips_percentiled as (
    SELECT 
        service_type, 
        year, 
        month,
        PERCENTILE_CONT(fare_amount, 0.9) OVER (PARTITION BY service_type, year, month) AS p90,
        PERCENTILE_CONT(fare_amount, 0.95) OVER (PARTITION BY service_type, year, month) AS p95,
        PERCENTILE_CONT(fare_amount, 0.97) OVER (PARTITION BY service_type, year, month) AS p97,
    FROM filter_fact_trips
)

select distinct * FROM trips_percentiled 
WHERE year=2020 and month=4