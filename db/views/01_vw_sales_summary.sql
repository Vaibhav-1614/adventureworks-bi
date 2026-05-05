CREATE OR REPLACE VIEW bi.vw_sales_summary AS
WITH sales_monthly AS (
    SELECT
        EXTRACT(YEAR FROM soh.order_date)::int AS year,
        EXTRACT(MONTH FROM soh.order_date)::int AS month,
        'Q' || EXTRACT(QUARTER FROM soh.order_date)::int AS quarter,
        soh.sales_person_id AS salesperson_id,
        st.name AS territory_name,
        st."group" AS territory_group,
        st.country_region_code,
        SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount))::numeric AS total_revenue,
        COUNT(DISTINCT soh.sales_order_id)::int AS total_orders,
        SUM(sod.order_qty)::numeric AS total_units
    FROM sales.sales_order_header soh
    JOIN sales.sales_order_detail sod
      ON sod.sales_order_id = soh.sales_order_id
    LEFT JOIN sales.sales_territory st
      ON st.territory_id = soh.territory_id
    WHERE soh.status = 5
      AND soh.sales_person_id IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),
quota_quarter AS (
    SELECT
        sqh.business_entity_id AS salesperson_id,
        EXTRACT(YEAR FROM sqh.quota_date)::int AS year,
        'Q' || EXTRACT(QUARTER FROM sqh.quota_date)::int AS quarter,
        AVG(sqh.sales_quota)::numeric AS quota
    FROM sales.sales_person_quota_history sqh
    GROUP BY 1, 2, 3
),
joined AS (
    SELECT
        sm.year,
        sm.month,
        sm.quarter,
        sm.salesperson_id,
        (p.first_name || ' ' || p.last_name)::text AS salesperson_name,
        sm.territory_name,
        sm.territory_group,
        sm.country_region_code,
        sm.total_revenue,
        sm.total_orders,
        sm.total_units,
        bi.safe_divide(sm.total_revenue, sm.total_orders) AS avg_order_value,
        COALESCE(qq.quota, 0)::numeric AS quota
    FROM sales_monthly sm
    JOIN sales.sales_person sp
      ON sp.business_entity_id = sm.salesperson_id
    JOIN person.person p
      ON p.business_entity_id = sp.business_entity_id
    LEFT JOIN quota_quarter qq
      ON qq.salesperson_id = sm.salesperson_id
     AND qq.year = sm.year
     AND qq.quarter = sm.quarter
)
SELECT
    j.year,
    j.month,
    j.quarter,
    j.salesperson_id,
    j.salesperson_name,
    j.territory_name,
    j.territory_group,
    j.country_region_code,
    j.total_revenue,
    j.total_orders,
    j.total_units,
    j.avg_order_value,
    j.quota,
    bi.safe_divide(j.total_revenue, NULLIF(j.quota, 0)) * 100 AS quota_attainment_pct,
    (j.total_revenue - j.quota) AS quota_variance,
    (COALESCE(bi.safe_divide(j.total_revenue, NULLIF(j.quota, 0)) * 100, 0) >= 100) AS above_quota,
    RANK() OVER (
        PARTITION BY j.year, j.month, j.territory_name
        ORDER BY j.total_revenue DESC
    ) AS rank_in_territory,
    RANK() OVER (
        PARTITION BY j.year, j.month
        ORDER BY j.total_revenue DESC
    ) AS rank_overall
FROM joined j
ORDER BY j.year, j.month, j.territory_name, j.salesperson_name;

COMMENT ON VIEW bi.vw_sales_summary IS
'Monthly salesperson and territory performance with revenue, quota attainment, and ranking metrics.';
