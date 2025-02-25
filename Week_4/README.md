# Homework 4: Analytics Engineering
## Preparations
In Kestra I created a workflow to download necessary dataset-files to my basket. Namely, I modified the workflow 06_gcp_taxi_scheduled adding one more option "fhv_shedule" (look file `zoomcamp.06_gcp_taxi_scheduled.yml`). This workflow downloaded additional files `fhv_tripdata` 2019 year.

After that I created external tables in my google cloud with data from `green`, `yellow` and `fhv` tables
```sql
CREATE OR REPLACE EXTERNAL TABLE `fair-canto-447119-p5.trip_data_all.green_tripdata` 
OPTIONS ( format = 'csv',
      uris = ['gs://kestra_de_zoomcamp_bucket/green_tripdata_2019-*.csv',
      'gs://kestra_de_zoomcamp_bucket/green_tripdata_2020-*.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `fair-canto-447119-p5.trip_data_all.yellow_tripdata` 
OPTIONS ( format = 'csv',
      uris = ['gs://kestra_de_zoomcamp_bucket/yellow_tripdata_2019-*.csv',
      'gs://kestra_de_zoomcamp_bucket/yellow_tripdata_2020-*.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `fair-canto-447119-p5.trip_data_all.fhv_tripdata` 
OPTIONS ( format = 'csv',
      uris = ['gs://kestra_de_zoomcamp_bucket/fhv_tripdata_2019-*.csv']
);
```

## Question 1: Understanding dbt model resolution
Provided you've got the following sources.yaml
```yaml
version: 2

sources:
  - name: raw_nyc_tripdata
    database: "{{ env_var('DBT_BIGQUERY_PROJECT', 'dtc_zoomcamp_2025') }}"
    schema:   "{{ env_var('DBT_BIGQUERY_SOURCE_DATASET', 'raw_nyc_tripdata') }}"
    tables:
      - name: ext_green_taxi
      - name: ext_yellow_taxi
```

with the following env variables setup where `dbt` runs:
```shell
export DBT_BIGQUERY_PROJECT=myproject
export DBT_BIGQUERY_DATASET=my_nyc_tripdata
```

What does this .sql model compile to?
```sql
select * 
from {{ source('raw_nyc_tripdata', 'ext_green_taxi' ) }}
```

- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.ext_green_taxi`
- `select * from dtc_zoomcamp_2025.my_nyc_tripdata.ext_green_taxi`
- `select * from myproject.raw_nyc_tripdata.ext_green_taxi`
- `select * from myproject.my_nyc_tripdata.ext_green_taxi`
- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.green_taxi`

### Solution
1. in the project's folder -> models -> create a new folder `q1_model` with two files:
sources.yml
q1.sql
2. Deploy -> Enviroments -> Enviroment variables -> Add nesessary variables
3. dbt compile --select q1_model
4. Project's folder -> target -> compiled -> my_new_project -> models -> q1_model -> q1.sql

And the answer from this file is:
```
select * from `myproject`.`raw_nyc_tripdata`.`ext_green_taxi`
```

## Question 2: dbt Variables & Dynamic Models

Say you have to modify the following dbt_model (`fct_recent_taxi_trips.sql`) to enable Analytics Engineers to dynamically control the date range. 

- In development, you want to process only **the last 7 days of trips**
- In production, you need to process **the last 30 days** for analytics

```sql
select *
from {{ ref('fact_taxi_trips') }}
where pickup_datetime >= CURRENT_DATE - INTERVAL '30' DAY
```

What would you change to accomplish that in a such way that command line arguments takes precedence over ENV_VARs, which takes precedence over DEFAULT value?

- Add `ORDER BY pickup_datetime DESC` and `LIMIT {{ var("days_back", 30) }}`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", 30) }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", "30") }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", var("days_back", "30")) }}' DAY`

### Solution
Values priority:
Through CLI (`dbt run --vars`)
From enviroment variables (env_var())
Values by default in `dbt_project.yml`

So, the right answer is:
`Update the WHERE clause to pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY`

## Question 3: dbt Data Lineage and Execution

Considering the data lineage below **and** that taxi_zone_lookup is the **only** materialization build (from a .csv seed file):

![image](./homework_q2.png)

Select the option that does **NOT** apply for materializing `fct_taxi_monthly_zone_revenue`:

- `dbt run`
- `dbt run --select +models/core/dim_taxi_trips.sql+ --target prod`
- `dbt run --select +models/core/fct_taxi_monthly_zone_revenue.sql`
- `dbt run --select +models/core/`
- `dbt run --select models/staging/+`

### Solution
dbt run --select models/staging/+

## Question 4: dbt Macros and Jinja
Consider you're dealing with sensitive data (e.g.: [PII](https://en.wikipedia.org/wiki/Personal_data)), that is **only available to your team and very selected few individuals**, in the `raw layer` of your DWH (e.g: a specific BigQuery dataset or PostgreSQL schema), 

 - Among other things, you decide to obfuscate/masquerade that data through your staging models, and make it available in a different schema (a `staging layer`) for other Data/Analytics Engineers to explore

- And **optionally**, yet  another layer (`service layer`), where you'll build your dimension (`dim_`) and fact (`fct_`) tables (assuming the [Star Schema dimensional modeling](https://www.databricks.com/glossary/star-schema)) for Dashboarding and for Tech Product Owners/Managers

You decide to make a macro to wrap a logic around it:

```sql
{% macro resolve_schema_for(model_type) -%}

    {%- set target_env_var = 'DBT_BIGQUERY_TARGET_DATASET'  -%}
    {%- set stging_env_var = 'DBT_BIGQUERY_STAGING_DATASET' -%}

    {%- if model_type == 'core' -%} {{- env_var(target_env_var) -}}
    {%- else -%}                    {{- env_var(stging_env_var, env_var(target_env_var)) -}}
    {%- endif -%}

{%- endmacro %}
```

And use on your staging, dim_ and fact_ models as:
```sql
{{ config(
    schema=resolve_schema_for('core'), 
) }}
```

That all being said, regarding macro above, **select all statements that are true to the models using it**:
- Setting a value for  `DBT_BIGQUERY_TARGET_DATASET` env var is mandatory, or it'll fail to compile
- Setting a value for `DBT_BIGQUERY_STAGING_DATASET` env var is mandatory, or it'll fail to compile
- When using `core`, it materializes in the dataset defined in `DBT_BIGQUERY_TARGET_DATASET`
- When using `stg`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET`
- When using `staging`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET`

### Solution
The true statements regarding the macro are:

1. Setting a value for DBT_BIGQUERY_TARGET_DATASET env var is mandatory, or it'll fail to compile
3. When using core, it materializes in the dataset defined in DBT_BIGQUERY_TARGET_DATASET
4. When using stg, it materializes in the dataset defined in DBT_BIGQUERY_STAGING_DATASET, or defaults to DBT_BIGQUERY_TARGET_DATASET
5. When using staging, it materializes in the dataset defined in DBT_BIGQUERY_STAGING_DATASET, or defaults to DBT_BIGQUERY_TARGET_DATASET

## Question 5: Taxi Quarterly Revenue Growth

1. Create a new model `fct_taxi_trips_quarterly_revenue.sql`
2. Compute the Quarterly Revenues for each year for based on `total_amount`
3. Compute the Quarterly YoY (Year-over-Year) revenue growth 
  * e.g.: In 2020/Q1, Green Taxi had -12.34% revenue growth compared to 2019/Q1
  * e.g.: In 2020/Q4, Yellow Taxi had +34.56% revenue growth compared to 2019/Q4

Considering the YoY Growth in 2020, which were the yearly quarters with the best (or less worse) and worst results for green, and yellow

- green: {best: 2020/Q2, worst: 2020/Q1}, yellow: {best: 2020/Q2, worst: 2020/Q1}
- green: {best: 2020/Q2, worst: 2020/Q1}, yellow: {best: 2020/Q3, worst: 2020/Q4}
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q2, worst: 2020/Q1}
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}
- green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q3, worst: 2020/Q4}

## Solution
The query is
```sql
SELECT yoy_growth, year, quarter, service_type, total_revenue, prev_year_revenue
FROM `fair-canto-447119-p5.dbt_ikameneva.fct_taxi_trips_quarterly_revenue` 
WHERE year=2020
ORDER BY yoy_growth DESC
LIMIT 10
```
and the response is:
```
+------------+------+---------+--------------+---------------+-------------------+
| yoy_growth | year | quarter | service_type | total_revenue | prev_year_revenue |
+------------+------+---------+--------------+---------------+-------------------+
|   -92.82   | 2020 |    2    |    Green     |    1544036.31 |          21498354 |
|   -92.23   | 2020 |    2    |   Yellow     |   15560734.74 |      200299536.73 |
|   -86.62   | 2020 |    3    |    Green     |    2360835.79 |       17651104.72 |
|   -84.43   | 2020 |    4    |    Green     |    2441470.26 |       15680616.87 |
|   -77.86   | 2020 |    3    |   Yellow     |   41404394.88 |      186986467.66 |
|    -70.6   | 2020 |    4    |   Yellow     |   56283855.99 |      191429478.83 |
|   -56.58   | 2020 |    1    |    Green     |   11480845.79 |       26440852.61 |
|   -21.13   | 2020 |    1    |   Yellow     |  144118825.38 |      182730698.14 |
+------------+------+---------+--------------+---------------+-------------------+
```
The answer is:
```
green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}
```
### Question 6: P97/P95/P90 Taxi Monthly Fare

1. Create a new model `fct_taxi_trips_monthly_fare_p95.sql`
2. Filter out invalid entries (`fare_amount > 0`, `trip_distance > 0`, and `payment_type_description in ('Cash', 'Credit Card')`)
3. Compute the **continous percentile** of `fare_amount` partitioning by service_type, year and and month

Now, what are the values of `p97`, `p95`, `p90` for Green Taxi and Yellow Taxi, in April 2020?

- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 52.0, p95: 37.0, p90: 25.5}
- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 31.5, p95: 25.5, p90: 19.0}
- green: {p97: 40.0, p95: 33.0, p90: 24.5}, yellow: {p97: 52.0, p95: 37.0, p90: 25.5}
- green: {p97: 40.0, p95: 33.0, p90: 24.5}, yellow: {p97: 31.5, p95: 25.5, p90: 19.0}
- green: {p97: 55.0, p95: 45.0, p90: 26.5}, yellow: {p97: 52.0, p95: 25.5, p90: 19.0}

### Solution
With the query
```sql
select * from `fair-canto-447119-p5.dbt_ikameneva.fct_taxi_trips_monthly_fare_p95`
```
I obtain the following result:
```
+--------------+------+-------+------+------+------+
| service_type | year | month |  p90 |  p95 |  p97 |
+--------------+------+-------+------+------+------+
|        Green | 2020 |     4 | 26.5 | 45.0 | 55.0 |
|       Yellow | 2020 |     4 | 19.0 | 25.5 | 31.5 |
+--------------+------+-------+------+------+------+
```

The answer is:
green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}

### Question 7: Top #Nth longest P90 travel time Location for FHV

Prerequisites:
* Create a staging model for FHV Data (2019), and **DO NOT** add a deduplication step, just filter out the entries where `where dispatching_base_num is not null`
* Create a core model for FHV Data (`dim_fhv_trips.sql`) joining with `dim_zones`. Similar to what has been done [here](../../../04-analytics-engineering/taxi_rides_ny/models/core/fact_trips.sql)
* Add some new dimensions `year` (e.g.: 2019) and `month` (e.g.: 1, 2, ..., 12), based on `pickup_datetime`, to the core model to facilitate filtering for your queries

Now...
1. Create a new model `fct_fhv_monthly_zone_traveltime_p90.sql`
2. For each record in `dim_fhv_trips.sql`, compute the [timestamp_diff](https://cloud.google.com/bigquery/docs/reference/standard-sql/timestamp_functions#timestamp_diff) in seconds between dropoff_datetime and pickup_datetime - we'll call it `trip_duration` for this exercise
3. Compute the **continous** `p90` of `trip_duration` partitioning by year, month, pickup_location_id, and dropoff_location_id

For the Trips that **respectively** started from `Newark Airport`, `SoHo`, and `Yorkville East`, in November 2019, what are **dropoff_zones** with the 2nd longest p90 trip_duration ?

- LaGuardia Airport, Chinatown, Garment District
- LaGuardia Airport, Park Slope, Clinton East
- LaGuardia Airport, Saint Albans, Howard Beach
- LaGuardia Airport, Rosedale, Bath Beach
- LaGuardia Airport, Yorkville East, Greenpoint

### Solution
The result table `fct_fhv_monthly_zone_traveltime_p90` have a view:
```
+----------------+--------------------+-------------------------------+
|    pickup_zone |                p90 |                  dropoff_zone |
+----------------+--------------------+-------------------------------+
|           SoHo |             21635.2|       Greenwich Village South |
|           SoHo |             19496.0|                     Chinatown |
|           SoHo | 18506.600000000002 |                          SoHo |
| Yorkville East | 18074.200000000004 | Sutton Place/Turtle Bay North |
|           SoHo | 16932.800000000003 |                  East Chelsea |
|           SoHo |            14903.1 |          TriBeCa/Civic Center |
| Yorkville East |            13846.0 |              Garment District |
|           SoHo |            11119.0 |                   Boerum Hill |
|           SoHo | 10986.800000000001 |                       Jamaica |
| Yorkville East |            10428.0 |                  Clinton East |
|           SoHo |             8517.9 |         Upper East Side North |
| Newark Airport |             8200.7 |     Williamsburg (South Side) |
|           SoHo |             7434.0 |                Pelham Parkway |
| Newark Airport | 7028.8000000000011 |             LaGuardia Airport |
| Yorkville East | 6969.0000000000009 |                Yorkville East |
+----------------+--------------------+-------------------------------+
```

So, the right answer is:
`LaGuardia Airport, Chinatown, Garment District`
