# Power BI Model Guide

Use a simple star-like model centered on monthly analytical views.

## Recommended relationships

- `vw_date_dimension[year, month]` -> `vw_executive_kpis[year, month]`
- `vw_date_dimension[year, month]` -> `vw_sales_summary[year, month]`
- `vw_date_dimension[year, month]` -> `vw_product_performance[year, month]`
- `vw_date_dimension[year, month]` -> `vw_customer_monthly[year, month]`
- `vw_date_dimension[year, month]` -> `vw_anomaly_variance[year, month]`
- `vw_customer_rfm[customer_id]` -> `vw_customer_monthly[customer_id]`

If your model requires a single date key, create one in Power Query:
`date_key = #date([year], [month], 1)`.

## Modeling notes

- Keep cross filter direction single where possible.
- Hide technical keys not needed by report users.
- Mark `vw_date_dimension` as Date table in Power BI.
- Create DAX measures in a dedicated measures table.
- Use SQL view columns for stable base metrics and DAX for context-sensitive calculations.
