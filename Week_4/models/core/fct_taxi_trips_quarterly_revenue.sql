{{
    config(
        materialized='table'
    )
}}

WITH quarterly_revenue AS (
    SELECT
        year,
        quarter,
        year_quarter,
        service_type,
        SUM(revenue_monthly_total_amount) AS total_revenue
    FROM {{ ref('dm_monthly_zone_revenue') }}
    GROUP BY 1, 2,3,4
),

cte_prev_year_revenue AS (
    SELECT 
        q_r.*, 
        LAG(q_r.total_revenue) OVER (
            PARTITION BY q_r.service_type, q_r.quarter
            ORDER BY q_r.year
        ) AS prev_year_revenue
    FROM quarterly_revenue q_r
),

YoY_revenue AS (
    SELECT
        q_r.year,
        q_r.quarter,
        q_r.year_quarter,
        q_r.service_type,
        q_r.total_revenue,
        pyr.prev_year_revenue,
        ROUND(
            (q_r.total_revenue - pyr.prev_year_revenue) / 
            NULLIF(pyr.prev_year_revenue, 0) * 100, 2
        ) AS yoy_growth
    FROM quarterly_revenue q_r
    JOIN cte_prev_year_revenue pyr 
    ON q_r.service_type = pyr.service_type 
    AND q_r.quarter = pyr.quarter 
    AND q_r.year = pyr.year
)

SELECT
    year,
    quarter,
    year_quarter,
    service_type,
    total_revenue,
    prev_year_revenue,
    yoy_growth
FROM YoY_revenue