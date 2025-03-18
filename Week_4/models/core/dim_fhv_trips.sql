{{
    config( 
        materialized='table'
    )
}}

with fhv_tripdata as (
    select *, 
    EXTRACT(YEAR FROM pickup_datetime) AS year,
    EXTRACT(month FROM pickup_datetime) AS month,

    from {{ ref('stg_fhv_tripdata') }}
), 
dim_zones as (
    select * from {{ ref('dim_zones') }}
)
select fhv_tripdata.dispatching_base_num, 
    fhv_tripdata.year,
    fhv_tripdata.month,
    pickup_zone.borough as pickup_borough, 
    pickup_zone.zone as pickup_zone, 
    dropoff_zone.borough as dropoff_borough, 
    dropoff_zone.zone as dropoff_zone, 
    fhv_tripdata.pickup_datetime,
    fhv_tripdata.dropOff_datetime,
    fhv_tripdata.pickup_locationid,
    fhv_tripdata.dropOff_locationid,
    fhv_tripdata.SR_Flag,
    fhv_tripdata.Affiliated_base_number
from fhv_tripdata
inner join dim_zones as pickup_zone
on fhv_tripdata.pickup_locationid = pickup_zone.locationid
inner join dim_zones as dropoff_zone
on fhv_tripdata.dropoff_locationid = dropoff_zone.locationid
-- tratata