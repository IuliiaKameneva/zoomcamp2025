{{
    config(
        materialized='view'
    )
}}

with fhv_tripdata as 
(
  select *,
  from {{ source('staging','fhv_tripdata') }}
  where dispatching_base_num is not null 
)
select
    -- identifiers
    {{ dbt.safe_cast("dispatching_base_num", api.Column.translate_type("string")) }} as dispatching_base_num,
    {{ dbt.safe_cast("pulocationid", api.Column.translate_type("integer")) }} as pickup_locationid,
    {{ dbt.safe_cast("dolocationid", api.Column.translate_type("integer")) }} as dropoff_locationid,
    
    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropOff_datetime as timestamp) as dropOff_datetime,
    
    -- trip info
    cast(SR_Flag as string) as SR_Flag,
    cast(Affiliated_base_number as string) as Affiliated_base_number,
    -- {{ dbt.safe_cast("trip_type", api.Column.translate_type("integer")) }} as trip_type,

from fhv_tripdata