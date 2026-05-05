CREATE OR REPLACE VIEW bi.vw_product_performance AS
WITH monthly AS (
    SELECT
        EXTRACT(YEAR FROM soh.order_date)::int AS year,
        EXTRACT(MONTH FROM soh.order_date)::int AS month,
        'Q' || EXTRACT(QUARTER FROM soh.order_date)::int AS quarter,
        p.product_id,
        p.name AS product_name,
        p.product_number,
        psc.name AS subcategory_name,
        pc.name AS category_name,
        p.color,
        p.size,
        p.weight,
        p.standard_cost,
        p.list_price,
        SUM(sod.order_qty)::numeric AS units_sold,
        SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount))::numeric AS gross_revenue,
        SUM(sod.order_qty * p.standard_cost)::numeric AS cogs,
        SUM(sod.order_qty * sod.unit_price * sod.unit_price_discount)::numeric AS discount_amount,
        AVG(sod.unit_price_discount)::numeric * 100 AS avg_discount_pct,
        SUM(CASE WHEN sod.order_qty < 0 THEN ABS(sod.order_qty) ELSE 0 END)::numeric AS return_qty
    FROM sales.sales_order_detail sod
    JOIN sales.sales_order_header soh
      ON soh.sales_order_id = sod.sales_order_id
    JOIN production.product p
      ON p.product_id = sod.product_id
    LEFT JOIN production.product_subcategory psc
      ON psc.product_subcategory_id = p.product_subcategory_id
    LEFT JOIN production.product_category pc
      ON pc.product_category_id = psc.product_category_id
    WHERE soh.status = 5
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
),
lifetime AS (
    SELECT
        p.product_id,
        SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount))::numeric AS lifetime_revenue,
        SUM(sod.order_qty)::numeric AS lifetime_units,
        bi.safe_divide(
            SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount)) - SUM(sod.order_qty * p.standard_cost),
            SUM(sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount))
        ) * 100 AS lifetime_margin_pct
    FROM sales.sales_order_detail sod
    JOIN sales.sales_order_header soh
      ON soh.sales_order_id = sod.sales_order_id
    JOIN production.product p
      ON p.product_id = sod.product_id
    WHERE soh.status = 5
    GROUP BY p.product_id
),
calc AS (
    SELECT
        m.*,
        (m.gross_revenue - m.cogs) AS gross_profit,
        bi.safe_divide((m.gross_revenue - m.cogs), m.gross_revenue) * 100 AS gross_margin_pct,
        bi.safe_divide(m.return_qty, NULLIF(m.units_sold, 0)) * 100 AS return_rate_pct
    FROM monthly m
)
SELECT
    c.year,
    c.month,
    c.quarter,
    c.product_id,
    c.product_name,
    c.product_number,
    c.subcategory_name,
    c.category_name,
    c.color,
    c.size,
    c.weight,
    c.standard_cost,
    c.list_price,
    c.units_sold,
    c.gross_revenue,
    c.cogs,
    c.gross_profit,
    c.gross_margin_pct,
    c.discount_amount,
    c.avg_discount_pct,
    c.return_qty,
    c.return_rate_pct,
    bi.safe_divide(
        c.gross_revenue - LAG(c.gross_revenue) OVER (PARTITION BY c.product_id ORDER BY c.year, c.month),
        LAG(c.gross_revenue) OVER (PARTITION BY c.product_id ORDER BY c.year, c.month)
    ) * 100 AS mom_revenue_change_pct,
    RANK() OVER (
        PARTITION BY c.year, c.month, c.category_name
        ORDER BY c.gross_revenue DESC
    ) AS revenue_rank,
    (
        RANK() OVER (
            PARTITION BY c.year, c.month, c.category_name
            ORDER BY c.gross_revenue DESC
        ) <= 10
    ) AS is_top_10,
    l.lifetime_revenue,
    l.lifetime_units,
    l.lifetime_margin_pct
FROM calc c
LEFT JOIN lifetime l
  ON l.product_id = c.product_id
ORDER BY c.year, c.month, c.category_name, c.product_name;

COMMENT ON VIEW bi.vw_product_performance IS
'Monthly product performance including profitability, returns, ranking, and lifetime rollups.';
