\echo '=== AdventureWorks BI View Validation ==='
\echo 'Running row count, null, revenue, date range, and duplicate checks'

WITH source_year_bounds AS (
    SELECT
        MIN(EXTRACT(YEAR FROM soh.order_date))::int AS source_min_year,
        MAX(EXTRACT(YEAR FROM soh.order_date))::int AS source_max_year
    FROM sales.sales_order_header soh
    WHERE soh.status = 5
),
checks AS (
    -- 1) Row count checks
    SELECT 'bi.vw_executive_kpis'::text AS view_name, 'row_count'::text AS check_name,
           CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status,
           'rows=' || COUNT(*)::text AS detail
    FROM bi.vw_executive_kpis
    UNION ALL
    SELECT 'bi.vw_sales_summary', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_sales_summary
    UNION ALL
    SELECT 'bi.vw_product_performance', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_product_performance
    UNION ALL
    SELECT 'bi.vw_customer_rfm', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_customer_rfm
    UNION ALL
    SELECT 'bi.vw_customer_monthly', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_customer_monthly
    UNION ALL
    SELECT 'bi.vw_hr_workforce', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_hr_workforce
    UNION ALL
    SELECT 'bi.vw_anomaly_variance', 'row_count', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END, 'rows=' || COUNT(*)::text
    FROM bi.vw_anomaly_variance

    -- 2) Key null checks (>5% null = FAIL)
    UNION ALL
    SELECT 'bi.vw_executive_kpis', 'key_nulls',
           CASE WHEN AVG((year IS NULL OR month IS NULL OR total_revenue IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((year IS NULL OR month IS NULL OR total_revenue IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_executive_kpis
    UNION ALL
    SELECT 'bi.vw_sales_summary', 'key_nulls',
           CASE WHEN AVG((salesperson_id IS NULL OR year IS NULL OR month IS NULL OR total_revenue IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((salesperson_id IS NULL OR year IS NULL OR month IS NULL OR total_revenue IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_sales_summary
    UNION ALL
    SELECT 'bi.vw_product_performance', 'key_nulls',
           CASE WHEN AVG((product_id IS NULL OR year IS NULL OR month IS NULL OR gross_revenue IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((product_id IS NULL OR year IS NULL OR month IS NULL OR gross_revenue IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_product_performance
    UNION ALL
    SELECT 'bi.vw_customer_rfm', 'key_nulls',
           CASE WHEN AVG((customer_id IS NULL OR full_name IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((customer_id IS NULL OR full_name IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_customer_rfm
    UNION ALL
    SELECT 'bi.vw_customer_monthly', 'key_nulls',
           CASE WHEN AVG((customer_id IS NULL OR year IS NULL OR month IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((customer_id IS NULL OR year IS NULL OR month IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_customer_monthly
    UNION ALL
    SELECT 'bi.vw_hr_workforce', 'key_nulls',
           CASE WHEN AVG((employee_id IS NULL OR department_name IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((employee_id IS NULL OR department_name IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_hr_workforce
    UNION ALL
    SELECT 'bi.vw_anomaly_variance', 'key_nulls',
           CASE WHEN AVG((metric_category IS NULL OR entity_name IS NULL OR value IS NULL)::int)::numeric <= 0.05 THEN 'PASS' ELSE 'FAIL' END,
           'null_rate=' || ROUND(AVG((metric_category IS NULL OR entity_name IS NULL OR value IS NULL)::int)::numeric * 100, 2)::text || '%'
    FROM bi.vw_anomaly_variance

    -- 3) Revenue sanity checks (where applicable)
    UNION ALL
    SELECT 'bi.vw_executive_kpis', 'revenue_sanity',
           CASE WHEN SUM(total_revenue) >= 1000000 THEN 'PASS' ELSE 'WARN' END,
           'total_revenue=' || ROUND(SUM(total_revenue), 2)::text
    FROM bi.vw_executive_kpis
    UNION ALL
    SELECT 'bi.vw_sales_summary', 'revenue_sanity',
           CASE WHEN SUM(total_revenue) >= 1000000 THEN 'PASS' ELSE 'WARN' END,
           'total_revenue=' || ROUND(SUM(total_revenue), 2)::text
    FROM bi.vw_sales_summary
    UNION ALL
    SELECT 'bi.vw_product_performance', 'revenue_sanity',
           CASE WHEN SUM(gross_revenue) >= 1000000 THEN 'PASS' ELSE 'WARN' END,
           'total_revenue=' || ROUND(SUM(gross_revenue), 2)::text
    FROM bi.vw_product_performance
    UNION ALL
    SELECT 'bi.vw_customer_monthly', 'revenue_sanity',
           CASE WHEN SUM(monthly_revenue) >= 1000000 THEN 'PASS' ELSE 'WARN' END,
           'total_revenue=' || ROUND(SUM(monthly_revenue), 2)::text
    FROM bi.vw_customer_monthly

    -- 4) Date range checks (where applicable)
    UNION ALL
    SELECT 'bi.vw_executive_kpis', 'date_range',
           CASE
               WHEN MIN(ek.year) = MIN(syb.source_min_year) AND MAX(ek.year) = MIN(syb.source_max_year) THEN 'PASS'
               ELSE 'WARN'
           END,
           'year_min=' || MIN(ek.year)::text || ', year_max=' || MAX(ek.year)::text ||
           ', expected_min=' || MIN(syb.source_min_year)::text || ', expected_max=' || MIN(syb.source_max_year)::text
    FROM bi.vw_executive_kpis ek
    CROSS JOIN source_year_bounds syb
    UNION ALL
    SELECT 'bi.vw_sales_summary', 'date_range',
           CASE
               WHEN MIN(s.year) = MIN(syb.source_min_year) AND MAX(s.year) = MIN(syb.source_max_year) THEN 'PASS'
               ELSE 'WARN'
           END,
           'year_min=' || MIN(s.year)::text || ', year_max=' || MAX(s.year)::text ||
           ', expected_min=' || MIN(syb.source_min_year)::text || ', expected_max=' || MIN(syb.source_max_year)::text
    FROM bi.vw_sales_summary s
    CROSS JOIN source_year_bounds syb
    UNION ALL
    SELECT 'bi.vw_product_performance', 'date_range',
           CASE
               WHEN MIN(p.year) = MIN(syb.source_min_year) AND MAX(p.year) = MIN(syb.source_max_year) THEN 'PASS'
               ELSE 'WARN'
           END,
           'year_min=' || MIN(p.year)::text || ', year_max=' || MAX(p.year)::text ||
           ', expected_min=' || MIN(syb.source_min_year)::text || ', expected_max=' || MIN(syb.source_max_year)::text
    FROM bi.vw_product_performance p
    CROSS JOIN source_year_bounds syb
    UNION ALL
    SELECT 'bi.vw_customer_monthly', 'date_range',
           CASE
               WHEN MIN(cm.year) = MIN(syb.source_min_year) AND MAX(cm.year) = MIN(syb.source_max_year) THEN 'PASS'
               ELSE 'WARN'
           END,
           'year_min=' || MIN(cm.year)::text || ', year_max=' || MAX(cm.year)::text ||
           ', expected_min=' || MIN(syb.source_min_year)::text || ', expected_max=' || MIN(syb.source_max_year)::text
    FROM bi.vw_customer_monthly cm
    CROSS JOIN source_year_bounds syb

    -- 5) Duplicate checks
    UNION ALL
    SELECT 'bi.vw_executive_kpis', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_executive_kpis
        GROUP BY year, month
    ) d
    UNION ALL
    SELECT 'bi.vw_sales_summary', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_sales_summary
        GROUP BY year, month, salesperson_id, territory_name
    ) d
    UNION ALL
    SELECT 'bi.vw_product_performance', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_product_performance
        GROUP BY year, month, product_id
    ) d
    UNION ALL
    SELECT 'bi.vw_customer_rfm', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_customer_rfm
        GROUP BY customer_id
    ) d
    UNION ALL
    SELECT 'bi.vw_customer_monthly', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_customer_monthly
        GROUP BY customer_id, year, month
    ) d
    UNION ALL
    SELECT 'bi.vw_hr_workforce', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_hr_workforce
        GROUP BY employee_id
    ) d
    UNION ALL
    SELECT 'bi.vw_anomaly_variance', 'duplicate_keys',
           CASE WHEN COALESCE(SUM(cnt), 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           'duplicate_rows=' || COALESCE(SUM(cnt), 0)::text
    FROM (
        SELECT GREATEST(COUNT(*) - 1, 0) AS cnt
        FROM bi.vw_anomaly_variance
        GROUP BY metric_category, entity_name, year, month
    ) d
),
summary AS (
    SELECT
        SUM((status = 'PASS')::int) AS pass_count,
        COUNT(*) AS total_count
    FROM checks
)
SELECT * FROM checks
UNION ALL
SELECT
    'SUMMARY' AS view_name,
    'overall' AS check_name,
    CASE WHEN s.pass_count = s.total_count THEN 'PASS' ELSE 'WARN' END AS status,
    s.pass_count::text || ' of ' || s.total_count::text || ' checks passed. Ready for Power BI: ' ||
    CASE WHEN s.pass_count = s.total_count THEN 'YES' ELSE 'NO' END AS detail
FROM summary s
ORDER BY view_name, check_name;

\echo '=== Validation complete ==='
