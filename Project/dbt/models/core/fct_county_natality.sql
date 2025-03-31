{{
  config(
    materialized='table',
    partition_by={
      "field": "year_date", 
      "data_type": "date",
      "granularity": "year"
    }
  )
}}

-- SELECT 
-- --   DATE(EXTRACT(YEAR FROM CAST(year AS DATE)), 1, 1) AS year_date,
-- --   EXTRACT(YEAR FROM CAST(year AS DATE)) AS year,
--   year_date,
--   year,
--   births,
--   ave_age_of_mother AS mother_age,
--   ave_oe_gestational_age_wks AS oe_gestational_age_wks,
--   ave_lmp_gestational_age_wks AS lmp_gestational_age_wks,
--   ave_birth_weight_gms AS birth_weight_gms,
--   ave_pre_pregnancy_bmi AS pre_pregnancy_bmi,
--   ave_number_of_prenatal_wks AS number_of_prenatal_wks
-- FROM {{ ref('stg_county_natality') }}

WITH county_natality_year as (
    SELECT 
        year_date,
        year,
        SUM(births) as births,
        SUM(births * ave_age_of_mother)/sum(births) AS mother_age, 
        SUM(births * ave_oe_gestational_age_wks)/sum(births) AS oe_gestational_age_wks, 
        SUM(births * ave_lmp_gestational_age_wks)/sum(births) AS lmp_gestational_age_wks, 
        SUM(births * ave_birth_weight_gms)/sum(births) AS birth_weight_gms, 
        SUM(births * ave_pre_pregnancy_bmi)/sum(births) AS pre_pregnancy_bmi, 
        SUM(births * ave_number_of_prenatal_wks)/sum(births) AS number_of_prenatal_wks, 
    FROM  {{ ref('stg_county_natality') }}
    group by 1,2
)

select * FROM county_natality_year 