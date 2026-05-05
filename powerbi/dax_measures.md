# Suggested DAX Measures

Create a `Measures` table and add:

```DAX
Total Revenue = SUM('vw_executive_kpis'[total_revenue])

Total Orders = SUM('vw_executive_kpis'[total_orders])

AOV = DIVIDE([Total Revenue], [Total Orders])

YTD Revenue = TOTALYTD([Total Revenue], 'vw_date_dimension'[date_key])

MoM Growth % =
VAR PrevMonthRevenue =
    CALCULATE([Total Revenue], DATEADD('vw_date_dimension'[date_key], -1, MONTH))
RETURN
    DIVIDE([Total Revenue] - PrevMonthRevenue, PrevMonthRevenue)

Quota Attainment % = AVERAGE('vw_sales_summary'[quota_attainment_pct])

Gross Margin % = AVERAGE('vw_product_performance'[gross_margin_pct])

Customer Lifetime Value = AVERAGE('vw_customer_rfm'[monetary])

Anomalies This Month =
CALCULATE(
    COUNTROWS('vw_anomaly_variance'),
    'vw_anomaly_variance'[is_anomaly] = TRUE()
)
```

Formatting tips:

- Percent fields: percentage with 1-2 decimals
- Currency fields: local currency format, 0-2 decimals
- Growth measures: set data colors with positive/negative conditional formatting
