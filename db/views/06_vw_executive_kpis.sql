CREATE OR REPLACE VIEW bi.vw_executive_kpis AS
WITH monthly AS (
    SELECT
        EXTRACT(YEAR FROM soh.order_date)::int AS year,
        EXTRACT(MONTH FROM soh.order_date)::int AS month,
        TO_CHAR(soh.order_date, 'Month')::text AS month_name,
        'Q' || EXTRACT(QUARTER FROM soh.order_date)::int AS quarter,
        SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount))::numeric AS total_revenue,
        COUNT(DISTINCT soh.sales_order_id)::int AS total_orders,
        SUM(sod.order_qty)::numeric AS total_units_sold,
        SUM(
            CASE WHEN soh.online_order_flag THEN sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount) ELSE 0 END
        )::numeric AS online_revenue,
        SUM(
            CASE WHEN NOT soh.online_order_flag THEN sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount) ELSE 0 END
        )::numeric AS offline_revenue
    FROM sales.sales_order_header soh
    JOIN sales.sales_order_detail sod
      ON sod.sales_order_id = soh.sales_order_id
    WHERE soh.status = 5
    GROUP BY 1, 2, 3, 4
),
base AS (
    SELECT
        m.*,
        bi.safe_divide(m.total_revenue, m.total_orders) AS avg_order_value
    FROM monthly m
)
SELECT
    b.year,
    b.month,
    TRIM(b.month_name) AS month_name,
    b.quarter,
    b.total_revenue,
    b.total_orders,
    b.total_units_sold,
    b.avg_order_value,
    bi.safe_divide(
        b.total_revenue - LAG(b.total_revenue) OVER (ORDER BY b.year, b.month),
        LAG(b.total_revenue) OVER (ORDER BY b.year, b.month)
    ) * 100 AS mom_revenue_change_pct,
    bi.safe_divide(
        b.total_revenue - LAG(b.total_revenue, 12) OVER (ORDER BY b.year, b.month),
        LAG(b.total_revenue, 12) OVER (ORDER BY b.year, b.month)
    ) * 100 AS yoy_revenue_change_pct,
    SUM(b.total_revenue) OVER (
        PARTITION BY b.year, b.quarter
        ORDER BY b.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS qtd_revenue,
    SUM(b.total_revenue) OVER (
        PARTITION BY b.year
        ORDER BY b.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_revenue,
    SUM(b.total_revenue) OVER (
        ORDER BY b.year, b.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue,
    b.online_revenue,
    b.offline_revenue,
    bi.safe_divide(b.online_revenue, b.total_revenue) * 100 AS online_pct
FROM base b
ORDER BY b.year, b.month;

COMMENT ON VIEW bi.vw_executive_kpis IS
'Monthly executive KPI rollup of shipped sales orders including trend and running-total metrics.';
