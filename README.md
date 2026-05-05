# AdventureWorks BI: PostgreSQL to Power BI Analytics Platform

End-to-end business intelligence project that transforms AdventureWorks OLTP data into a validated analytics layer and a multi-page Power BI reporting solution for executive and operational decision-making.

## Overview

This project simulates a production BI workflow:

- Model transactional data into reusable analytical views in PostgreSQL
- Validate output quality with automated SQL checks
- Design a Power BI semantic model and dashboard pages
- Document business insights and stakeholder-facing outputs

## Business Questions Answered

- How are revenue, orders, and average order value trending over time?
- Which territories, salespeople, and products drive performance?
- Which customer segments create the most value and where is risk increasing?
- Which KPI movements are anomalous relative to historical behavior?

## Tech Stack

- PostgreSQL
- SQL (CTEs, window functions, aggregations, validation queries)
- Power BI Desktop

## Analytics Layer

Implemented BI views in schema `bi`:

- `bi.vw_date_dimension`
- `bi.vw_executive_kpis`
- `bi.vw_sales_summary`
- `bi.vw_product_performance`
- `bi.vw_customer_rfm`
- `bi.vw_customer_monthly`
- `bi.vw_hr_workforce`
- `bi.vw_anomaly_variance`

## Data Quality and Validation

`validation/validate_views.sql` performs checks for:

- Row-count completeness
- Key-field null rates
- Revenue sanity thresholds
- Dynamic date-range consistency
- Duplicate-key violations

Latest validation status:

- `29 / 29` checks passed
- Ready for Power BI: `YES`

## Notable Outcomes

- Built a modular SQL reporting layer with reusable business metrics
- Identified territory and product concentration patterns in revenue
- Quantified channel mix (`online_pct`) and trend anomalies
- Produced insight documentation with business impact and action recommendations

## Project Structure

- `db/setup.sql` - schema bootstrap, grants, helper functions
- `db/views/*.sql` - analytical view definitions
- `validation/validate_views.sql` - quality checks
- `powerbi/connection_guide.md` - report build instructions
- `powerbi/model_guide.md` - semantic model design
- `powerbi/dax_measures.md` - suggested DAX measures
- `docs/business_questions.md` - business framing
- `docs/schema_diagram.md` - source model walkthrough
- `docs/insights.md` - final insight write-up
- `screenshots/README.md` - screenshot checklist for portfolio use

## Run Order

1. Execute `db/setup.sql`
2. Execute all files in `db/views/` in the documented order
3. Execute `validation/validate_views.sql`
4. Build dashboard pages using `powerbi/connection_guide.md`

## Notes

- SQL targets lowercase snake_case AdventureWorks PostgreSQL schema naming
- `powerbi_reader` is configured as a read-only reporting role
