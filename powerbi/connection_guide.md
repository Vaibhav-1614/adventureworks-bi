# Power BI Connection Guide

## Section 1 - Connect Power BI to PostgreSQL

1. Install the PostgreSQL driver used by Power BI (`Npgsql`):
   - Download: [https://www.npgsql.org/doc/installation.html](https://www.npgsql.org/doc/installation.html)
2. Open Power BI Desktop.
3. Select **Get Data -> PostgreSQL database**.
4. Enter:
   - **Server**: `localhost`
   - **Database**: `adventureworks`
5. Sign in with database credentials:
   - **Username**: `powerbi_reader`
   - **Password**: the value configured in `db/setup.sql`
6. For **Data Connectivity mode**, choose **Import**.
   - Why Import: better performance for portfolio projects, easier DAX and visuals, no live-query latency.
   - Why not DirectQuery: slower interactions and more database dependency during demo/review.
7. Import these BI views:
   - `bi.vw_date_dimension`
   - `bi.vw_executive_kpis`
   - `bi.vw_sales_summary`
   - `bi.vw_product_performance`
   - `bi.vw_customer_rfm`
   - `bi.vw_customer_monthly`
   - `bi.vw_hr_workforce`
   - `bi.vw_anomaly_variance`

Recommended import order:
1) `vw_date_dimension`
2) `vw_executive_kpis`
3) `vw_sales_summary`
4) `vw_product_performance`
5) `vw_customer_monthly`
6) `vw_customer_rfm`
7) `vw_hr_workforce`
8) `vw_anomaly_variance`

## Section 2 - Build pages

## Page 1 - Executive Summary

- KPI cards:
  - YTD Revenue
  - Total Orders
  - AOV
  - MoM Growth %
- Apply conditional formatting for MoM Growth:
  - positive = green
  - negative = red
- Line chart: monthly revenue trend with YTD line
- Clustered bar chart: online vs offline revenue by quarter
- Slicer: year (single select)
- Source: `vw_executive_kpis`

## Page 2 - Sales Performance

- Matrix:
  - rows = salesperson
  - columns = month
  - values = revenue
  - conditional formatting by quota attainment
- Bar chart:
  - top 10 salespeople by YTD revenue
  - quota reference line overlay
- Map: revenue by `territory_group`
- KPI card: % of salespeople above quota (current month)
- Slicers: year, territory, quarter
- Source: `vw_sales_summary`

## Page 3 - Product Intelligence

- Bar chart: top 15 products by gross margin %
- Treemap: category -> subcategory -> product by revenue
- Scatter:
  - x = units_sold
  - y = gross_margin_pct
  - size = gross_revenue
  - color = category
- Table: bottom 10 products by margin and return rate
- Slicer: category, year
- Source: `vw_product_performance`

## Page 4 - Customer Analytics

- Donut: customer count by RFM segment
- Bar: average CLV by segment
- Line: new vs returning customers per month
- Map: revenue by state/country
- Table: top 20 customers by lifetime value with segment badge
- Slicers: territory, segment
- Sources: `vw_customer_rfm`, `vw_customer_monthly`

## Page 5 - Anomaly Report

- Table: anomalies sorted by absolute z-score descending
- Conditional formatting by severity:
  - MILD = yellow
  - MODERATE = orange
  - SEVERE = red
- Bar chart: anomaly count by metric category
- Line chart: selected entity actual value vs historical mean
- KPI card: total anomalies this month
- Slicers: severity, metric category, direction
- Source: `vw_anomaly_variance`

## Section 3 - Publish to Power BI Service

1. In Power BI Desktop, click **Publish** and sign in to [https://app.powerbi.com](https://app.powerbi.com).
2. Publish to **My Workspace** (or a portfolio workspace).
3. In Power BI Service:
   - open the dataset settings
   - configure PostgreSQL credentials
   - set scheduled refresh (for example, daily at 8 AM)
4. Share:
   - use **Share** to generate a view link for recruiters/hiring managers
   - if needed, use **Publish to web** for public portfolio embedding

Screenshot tips for portfolio use:
- Capture **Page 1 Executive Summary** first (best resume thumbnail).
- Capture **Page 3 Product Intelligence** to show analytical depth.
- Capture **Page 5 Anomaly Report** to show advanced KPI monitoring.
