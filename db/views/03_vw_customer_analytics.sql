CREATE OR REPLACE VIEW bi.vw_customer_rfm AS
WITH customer_base AS (
    SELECT
        c.customer_id,
        c.person_id,
        (p.first_name || ' ' || p.last_name)::text AS full_name,
        ea.email_address,
        addr.city,
        addr.state_province,
        addr.country_region_code AS country_region,
        st.name AS territory_name
    FROM sales.customer c
    LEFT JOIN person.person p
      ON p.business_entity_id = c.person_id
    LEFT JOIN LATERAL (
        SELECT e.email_address
        FROM person.email_address e
        WHERE e.business_entity_id = c.person_id
        ORDER BY e.email_address_id
        LIMIT 1
    ) ea ON TRUE
    LEFT JOIN LATERAL (
        SELECT
            a.city,
            sp.name AS state_province,
            sp.country_region_code
        FROM person.business_entity_address bea
        JOIN person.address a
          ON a.address_id = bea.address_id
        LEFT JOIN person.state_province sp
          ON sp.state_province_id = a.state_province_id
        WHERE bea.business_entity_id = c.person_id
        ORDER BY bea.address_type_id, bea.address_id
        LIMIT 1
    ) addr ON TRUE
    LEFT JOIN sales.sales_territory st
      ON st.territory_id = c.territory_id
),
customer_sales AS (
    SELECT
        soh.customer_id,
        MIN(soh.order_date)::date AS first_order_date,
        MAX(soh.order_date)::date AS last_order_date,
        COUNT(DISTINCT soh.sales_order_id)::int AS frequency,
        SUM(
            CASE
                WHEN soh.status = 5
                THEN sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount)
                ELSE 0
            END
        )::numeric AS monetary
    FROM sales.sales_order_header soh
    JOIN sales.sales_order_detail sod
      ON sod.sales_order_id = soh.sales_order_id
    GROUP BY soh.customer_id
),
rfm_prep AS (
    SELECT
        cb.customer_id,
        cb.full_name,
        cb.email_address,
        cb.city,
        cb.state_province,
        cb.country_region,
        cb.territory_name,
        cs.first_order_date,
        cs.last_order_date,
        bi.days_between(cs.first_order_date, CURRENT_DATE) AS tenure_days,
        bi.days_between(cs.last_order_date, CURRENT_DATE) AS recency_days,
        cs.frequency,
        cs.monetary,
        bi.safe_divide(cs.monetary, cs.frequency) AS avg_order_value
    FROM customer_base cb
    JOIN customer_sales cs
      ON cs.customer_id = cb.customer_id
),
scored AS (
    SELECT
        r.*,
        6 - NTILE(5) OVER (ORDER BY r.recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY r.frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY r.monetary ASC) AS m_score
    FROM rfm_prep r
)
SELECT
    s.customer_id,
    s.full_name,
    s.email_address,
    s.city,
    s.state_province,
    s.country_region,
    s.territory_name,
    s.first_order_date,
    s.last_order_date,
    s.tenure_days,
    s.recency_days,
    s.frequency,
    s.monetary,
    s.avg_order_value,
    s.r_score,
    s.f_score,
    s.m_score,
    (s.r_score::text || s.f_score::text || s.m_score::text) AS rfm_score,
    CASE
        WHEN s.r_score >= 4 AND s.f_score >= 4 AND s.m_score >= 4 THEN 'Champions'
        WHEN s.f_score >= 4 AND s.m_score >= 3 THEN 'Loyal'
        WHEN s.r_score <= 2 AND s.f_score >= 3 THEN 'At Risk'
        WHEN s.r_score = 1 AND s.f_score <= 2 THEN 'Lost'
        WHEN s.tenure_days <= 90 THEN 'New'
        WHEN s.r_score >= 3 AND s.f_score <= 2 THEN 'Potential'
        ELSE 'Others'
    END AS segment,
    (s.frequency > 1) AS is_returning
FROM scored s;

COMMENT ON VIEW bi.vw_customer_rfm IS
'Customer-level RFM segmentation with geography, recency, frequency, monetary value, and segment labels.';

CREATE OR REPLACE VIEW bi.vw_customer_monthly AS
WITH monthly AS (
    SELECT
        soh.customer_id,
        EXTRACT(YEAR FROM soh.order_date)::int AS year,
        EXTRACT(MONTH FROM soh.order_date)::int AS month,
        SUM(
            CASE
                WHEN soh.status = 5
                THEN sod.order_qty * sod.unit_price * (1 - sod.unit_price_discount)
                ELSE 0
            END
        )::numeric AS monthly_revenue,
        COUNT(DISTINCT soh.sales_order_id)::int AS monthly_orders
    FROM sales.sales_order_header soh
    JOIN sales.sales_order_detail sod
      ON sod.sales_order_id = soh.sales_order_id
    GROUP BY 1,2,3
),
first_order AS (
    SELECT
        soh.customer_id,
        MIN(date_trunc('month', soh.order_date)) AS first_order_month
    FROM sales.sales_order_header soh
    GROUP BY soh.customer_id
)
SELECT
    m.customer_id,
    m.year,
    m.month,
    m.monthly_revenue,
    m.monthly_orders,
    (
      date_trunc('month', make_date(m.year, m.month, 1)) = f.first_order_month
    ) AS is_new_this_month,
    SUM(m.monthly_revenue) OVER (
        PARTITION BY m.customer_id
        ORDER BY m.year, m.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM monthly m
JOIN first_order f
  ON f.customer_id = m.customer_id
ORDER BY m.customer_id, m.year, m.month;

COMMENT ON VIEW bi.vw_customer_monthly IS
'Customer monthly trend table with revenue, order counts, first-month flag, and cumulative revenue.';
