CREATE OR REPLACE VIEW bi.vw_anomaly_variance AS
WITH metric_long AS (
    SELECT
        'product_monthly_revenue'::text AS metric_category,
        (p.product_id::text || ' - ' || p.product_name)::text AS entity_name,
        p.year,
        p.month,
        p.gross_revenue::numeric AS value
    FROM bi.vw_product_performance p

    UNION ALL

    SELECT
        'territory_monthly_revenue'::text AS metric_category,
        s.territory_name::text AS entity_name,
        s.year,
        s.month,
        SUM(s.total_revenue)::numeric AS value
    FROM bi.vw_sales_summary s
    GROUP BY s.territory_name, s.year, s.month

    UNION ALL

    SELECT
        'salesperson_monthly_revenue'::text AS metric_category,
        (s.salesperson_id::text || ' - ' || s.salesperson_name)::text AS entity_name,
        s.year,
        s.month,
        SUM(s.total_revenue)::numeric AS value
    FROM bi.vw_sales_summary s
    GROUP BY
        s.salesperson_id,
        s.salesperson_name,
        s.year,
        s.month

    UNION ALL

    SELECT
        'customer_monthly_orders'::text AS metric_category,
        cm.customer_id::text AS entity_name,
        cm.year,
        cm.month,
        cm.monthly_orders::numeric AS value
    FROM bi.vw_customer_monthly cm
),
stats AS (
    SELECT
        ml.*,
        AVG(ml.value) OVER (PARTITION BY ml.metric_category, ml.entity_name) AS historical_mean,
        STDDEV_SAMP(ml.value) OVER (PARTITION BY ml.metric_category, ml.entity_name) AS historical_stddev,
        MIN(ml.value) OVER (PARTITION BY ml.metric_category, ml.entity_name) AS historical_min,
        MAX(ml.value) OVER (PARTITION BY ml.metric_category, ml.entity_name) AS historical_max
    FROM metric_long ml
),
scored AS (
    SELECT
        s.*,
        bi.safe_divide(
            s.value - s.historical_mean,
            NULLIF(s.historical_stddev, 0)
        ) AS z_score,
        bi.safe_divide(
            s.value - s.historical_mean,
            NULLIF(s.historical_mean, 0)
        ) * 100 AS pct_vs_mean
    FROM stats s
),
dated AS (
    SELECT
        sc.*,
        make_date(sc.year, sc.month, 1) AS month_date
    FROM scored sc
),
recent_cutoff AS (
    SELECT date_trunc('month', MAX(month_date)) - interval '2 months' AS min_month
    FROM dated
)
SELECT
    d.metric_category,
    d.entity_name,
    d.year,
    d.month,
    d.value,
    d.historical_mean,
    d.historical_stddev,
    d.historical_min,
    d.historical_max,
    d.z_score,
    (ABS(d.z_score) > 2) AS is_anomaly,
    CASE
        WHEN d.z_score > 2 THEN 'SPIKE'
        WHEN d.z_score < -2 THEN 'DROP'
        ELSE 'NORMAL'
    END AS anomaly_direction,
    CASE
        WHEN ABS(d.z_score) > 3 THEN 'SEVERE'
        WHEN ABS(d.z_score) > 2.5 THEN 'MODERATE'
        WHEN ABS(d.z_score) >= 2 THEN 'MILD'
        ELSE 'NORMAL'
    END AS anomaly_severity,
    d.pct_vs_mean
FROM dated d
CROSS JOIN recent_cutoff rc
WHERE d.month_date >= rc.min_month;

COMMENT ON VIEW bi.vw_anomaly_variance IS
'Recent-month anomaly detection view using z-scores against entity-level historical baselines.';
