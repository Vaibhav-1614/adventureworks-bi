# AdventureWorks BI Project Checklist

## Completed

- [x] BI schema and setup script created (`db/setup.sql`).
- [x] Analytical views created (`db/views/00` through `06` scripts).
- [x] Validation script created (`validation/validate_views.sql`).
- [x] Power BI connection and modeling documentation created.
- [x] DAX starter measures documented (`powerbi/dax_measures.md`).
- [x] Business framing and schema notes documented (`docs/business_questions.md`, `docs/schema_diagram.md`).
- [x] Insight write-up completed with concrete metrics (`docs/insights.md`).

## Remaining (Manual)

- [x] Execute SQL scripts against PostgreSQL in the documented run order.
- [x] Run `validation/validate_views.sql`.
- [x] Resolve validation findings (duplicate keys + date-range checks now passing).
- [ ] Build the Power BI report pages using `powerbi/connection_guide.md`.
- [ ] Save portfolio screenshots in `screenshots/`:
  - [ ] `01_executive_summary.png`
  - [ ] `02_sales_performance.png`
  - [ ] `03_product_intelligence.png`
  - [ ] `04_customer_analytics.png`
  - [ ] `05_anomaly_report.png`
- [ ] Publish report to Power BI Service and verify refresh settings.
