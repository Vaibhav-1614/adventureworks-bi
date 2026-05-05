# AdventureWorks BI (PostgreSQL + Power BI)

Production-style BI portfolio project that transforms AdventureWorks OLTP data into a curated analytics layer and a multi-page Power BI report for executive and functional decision-making.

## Problem Statement

Raw transactional data is difficult to use directly in reporting. This project creates a reusable BI layer that answers critical business questions across:

- Executive performance and growth trends
- Sales rep and territory performance
- Product revenue and margin quality
- Customer value and retention risk
- Metric anomaly monitoring

## Solution Overview

The project implements:

1. A dedicated PostgreSQL schema (`bi`) with reusable helper functions
2. Analytical SQL views for each dashboard domain
3. A validation script to check row counts, key nulls, duplicates, revenue sanity, and date ranges
4. Power BI modeling and DAX guidance for report construction

## Tech Stack

- PostgreSQL (analytics layer)
- SQL (view modeling + validation)
- Power BI Desktop (semantic model + dashboards)

## BI Data Model (Views)

- `bi.vw_date_dimension`
- `bi.vw_executive_kpis`
- `bi.vw_sales_summary`
- `bi.vw_product_performance`
- `bi.vw_customer_rfm`
- `bi.vw_customer_monthly`
- `bi.vw_hr_workforce`
- `bi.vw_anomaly_variance`

## Repository Structure

- `db/setup.sql` - BI schema, role grants, and helper functions
- `db/views/*.sql` - analytical views in `bi` schema
- `validation/validate_views.sql` - data quality checks
- `powerbi/connection_guide.md` - Power BI connection and report build steps
- `powerbi/model_guide.md` - semantic model design
- `powerbi/dax_measures.md` - suggested DAX measures
- `docs/business_questions.md` - business framing
- `docs/schema_diagram.md` - source schema walkthrough
- `docs/insights.md` - quantified business insights
- `screenshots/README.md` - screenshot naming checklist

## Setup and Run Order

1. Execute `db/setup.sql`
2. Execute `db/views/00_vw_date_dimension.sql`
3. Execute `db/views/06_vw_executive_kpis.sql`
4. Execute `db/views/01_vw_sales_summary.sql`
5. Execute `db/views/02_vw_product_performance.sql`
6. Execute `db/views/03_vw_customer_analytics.sql`
7. Execute `db/views/04_vw_hr_workforce.sql`
8. Execute `db/views/05_vw_anomaly_variance.sql`
9. Execute `validation/validate_views.sql`
10. Build Power BI report pages using `powerbi/connection_guide.md`

## Validation Status (Latest Run)

- Created all target `bi` views successfully
- Validation result: `29 / 29` checks passed
- Ready for Power BI: `YES`

## Key Insights Produced

- Revenue concentration is highest in North America (Southwest, Canada, Northwest)
- Top product revenue is dominated by Mountain-200 variants
- Online channel contributes `26.73%` of subtotal revenue
- Latest month appears to be a partial period and should be flagged in KPI logic

See `docs/insights.md` for the full evidence and recommended actions.

## Portfolio Output Checklist

- [ ] Build 5-page Power BI report
- [ ] Export screenshots in `screenshots/`
- [ ] Publish to Power BI Service with refresh configuration

## Notes

- SQL assumes lowercase snake_case PostgreSQL AdventureWorks naming.
- Update names if your source schema differs.
- `powerbi_reader` is designed as a read-only reporting role.
