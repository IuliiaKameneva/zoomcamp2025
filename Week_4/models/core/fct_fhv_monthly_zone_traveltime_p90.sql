{{ config(materialized='table') }}

WITH fhv_trips_with_diff AS (
    SELECT 
        *,
        TIMESTAMP_DIFF(dropOff_datetime, pickup_datetime, SECOND) AS trip_duration
    FROM {{ ref('dim_fhv_trips') }}
),
fhv_trips_p90 as (
    SELECT 
        year, month, pickup_locationid, dropOff_locationid,
        pickup_zone,
        pickup_borough,
        dropoff_zone,
        dropoff_borough,
        PERCENTILE_CONT(trip_duration, 0.9) OVER (PARTITION BY year, month, pickup_locationid, dropOff_locationid) AS p90
    FROM fhv_trips_with_diff
)
select distinct pickup_zone, p90, dropoff_zone from fhv_trips_p90
where year=2019 and month=11 and pickup_zone in ('Newark Airport', 'SoHo', 'Yorkville East')
order by p90 desc