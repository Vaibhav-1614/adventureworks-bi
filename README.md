# AdventureWorks BI: PostgreSQL Analytics Layer + BI Dashboard

End-to-end business intelligence project that turns AdventureWorks OLTP data into a validated PostgreSQL analytics layer (`bi.*` views) with a five-page reporting solution for executive and operational decisions. The report is specified for Power BI and also implemented as a runnable web dashboard.

![Executive summary](screenshots/01_executive_summary.png)

## Overview

This project simulates a production BI workflow:

- Load the OLTP extract into PostgreSQL (`db/bootstrap_adventureworks.sql`)
- Model it into reusable analytical views with CTEs and window functions
- Validate the output with automated SQL checks (29/29 passing)
- Serve five report pages: a web dashboard (`dashboard/app.py`) plus the Power BI model, DAX, and page specifications (`powerbi/`)
- Document business insights and recommended actions (`docs/insights.md`)

## Business Questions Answered

- How are revenue, orders, and average order value trending over time?
- Which territories, salespeople, and products drive performance, and who is above or below quota?
- Which customer segments create the most value and where is risk increasing?
- Which KPI movements are anomalous relative to historical behaviour?

## Dashboard

| Sales Performance | Product Intelligence |
|---|---|
| ![Sales performance](screenshots/02_sales_performance.png) | ![Product intelligence](screenshots/03_product_intelligence.png) |
| **Customer Analytics** | **Anomaly Report** |
| ![Customer analytics](screenshots/04_customer_analytics.png) | ![Anomaly report](screenshots/05_anomaly_report.png) |

Headline numbers (May 2022 – Jun 2025): **$109.8M revenue**, 30.6K orders, 8.5% gross margin (bikes run at about 5% while accessories run above 50%), **87% overall quota attainment**, and Champions (13% of customers) generating **69% of customer revenue**.

## Tech Stack

- PostgreSQL 16 (CTEs, window functions, `LATERAL` joins, SQL functions)
- SQL validation suite
- Streamlit + Plotly web dashboard
- Power BI Desktop specification (semantic model, DAX measures, page layouts)

## Analytics Layer

Views in schema `bi`:

| View | Grain | Purpose |
|---|---|---|
| `vw_date_dimension` | day | calendar attributes for time intelligence |
| `vw_executive_kpis` | month | revenue, orders, AOV, MoM/YoY, QTD/YTD, channel mix, `is_complete_month` |
| `vw_sales_summary` | salesperson × territory × month | revenue, quota, attainment, rankings |
| `vw_product_performance` | product × month | revenue, COGS, margin, discounts, returns, rank |
| `vw_customer_rfm` | customer | recency / frequency / monetary scores and segment |
| `vw_customer_monthly` | customer × month | monthly revenue, new-customer flag, cumulative value |
| `vw_hr_workforce` | employee | department, tenure and age bands, pay, quota for salespeople |
| `vw_anomaly_variance` | entity × month | z-score anomalies for the last three complete months |

### Correctness fixes

Fixed during review. Validation passed before and after, because these were logic errors rather than data-quality failures.

- **RFM recency score was inverted.** `6 - NTILE(5) OVER (ORDER BY recency_days DESC)` gave the *oldest* buyers the best score, so "Champions" had not ordered in 660+ days. Champions now last ordered 1–129 days before the data ends and average $31K lifetime value.
- **Quota attainment was understated about 3×.** Quarterly quotas were compared with monthly revenue, and repeated for every territory a rep sold into in that month. The monthly quota is now a third of the quarterly quota, split across territory rows by revenue share. Average rep-month attainment was about 30% with under 1% of rep-months above quota; overall attainment is now 87%, with 36% of rep-months above quota.
- **Recency and tenure used `CURRENT_DATE`.** The data is a historical snapshot, so everyone fell into the same bucket (no "New" customers, every employee "10yr+"). Metrics are now anchored to `bi.as_of_date()`, the last order date.
- **Partial final month.** The extract stops on 29 Jun 2025. `vw_executive_kpis.is_complete_month` flags it, and the anomaly view scores complete months only, so a partial month is not reported as a -97% revenue collapse.
- **Performance.** The bootstrap now adds primary keys and join indexes. The full rebuild plus validation dropped from over 3 minutes to about 8 seconds.

## Data Quality and Validation

`validation/validate_views.sql` checks row-count completeness, key-field null rates, revenue sanity thresholds, dynamic date-range consistency, and duplicate keys.

Latest validation status: **29 / 29 checks passed**, Ready for Power BI: **YES**.

## Project Structure

- `db/bootstrap_adventureworks.sql`: creates the source schemas, loads `tmp/*.tsv`, adds keys and indexes
- `db/setup.sql`: `bi` schema, read-only `powerbi_reader` role, helper functions
- `db/views/*.sql`: analytical view definitions (run in numeric order)
- `validation/validate_views.sql`: quality checks
- `dashboard/app.py`: five-page Streamlit dashboard over the `bi` views
- `powerbi/`: Power BI connection guide, semantic model, DAX measures
- `docs/`: business questions, schema walkthrough, insights
- `tmp/`: AdventureWorks OLTP extract as tab-separated files

## Run Order

Run from the repository root (the bootstrap loads `tmp/*.tsv` with relative paths):

```bash
createdb adventureworks
psql -d adventureworks -f db/bootstrap_adventureworks.sql
psql -d adventureworks -v powerbi_reader_password='choose-a-password' -f db/setup.sql
for f in db/views/*.sql; do psql -d adventureworks -f "$f"; done
psql -d adventureworks -f validation/validate_views.sql
```

Launch the dashboard:

```bash
python -m pip install -r requirements.txt
AW_DATABASE_URL=postgresql+psycopg2://postgres:password@localhost:5432/adventureworks streamlit run dashboard/app.py
```

To build the Power BI version, follow `powerbi/connection_guide.md` and connect as `powerbi_reader`.

## Notes

- SQL targets lowercase snake_case AdventureWorks PostgreSQL naming.
- `powerbi_reader` is a read-only reporting role. Its password is supplied at run time with `-v powerbi_reader_password=...` and is never committed.
