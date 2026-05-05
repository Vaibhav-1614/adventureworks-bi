CREATE OR REPLACE VIEW bi.vw_date_dimension AS
WITH bounds AS (
    SELECT
        MIN(soh.order_date)::date AS min_date,
        MAX(soh.order_date)::date AS max_date
    FROM sales.sales_order_header soh
),
dates AS (
    SELECT gs::date AS date_key
    FROM bounds b
    CROSS JOIN generate_series(b.min_date, b.max_date, interval '1 day') gs
)
SELECT
    d.date_key,
    EXTRACT(YEAR FROM d.date_key)::int AS year,
    EXTRACT(MONTH FROM d.date_key)::int AS month,
    TO_CHAR(d.date_key, 'Month')::text AS month_name,
    'Q' || EXTRACT(QUARTER FROM d.date_key)::int AS quarter,
    TO_CHAR(d.date_key, 'YYYY-MM')::text AS year_month,
    EXTRACT(DAY FROM d.date_key)::int AS day_of_month,
    EXTRACT(DOY FROM d.date_key)::int AS day_of_year,
    EXTRACT(WEEK FROM d.date_key)::int AS week_of_year
FROM dates d
ORDER BY d.date_key;

COMMENT ON VIEW bi.vw_date_dimension IS
'Date dimension generated from sales order date bounds for Power BI time intelligence.';
