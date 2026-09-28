# AdventureWorks BI Project Checklist

## Completed

- [x] BI schema and setup script created (`db/setup.sql`).
- [x] Analytical views created (`db/views/00` through `06` scripts).
- [x] Validation script created (`validation/validate_views.sql`).
- [x] Power BI connection and modeling documentation created.
- [x] DAX starter measures documented (`powerbi/dax_measures.md`).
- [x] Business framing and schema notes documented (`docs/business_questions.md`, `docs/schema_diagram.md`).
- [x] Insight write-up completed with concrete metrics (`docs/insights.md`).
- [x] Execute SQL scripts against PostgreSQL in the documented run order.
- [x] Run `validation/validate_views.sql` (29/29 passing).
- [x] Resolve validation findings (duplicate keys + date-range checks now passing).
- [x] Fix RFM recency direction, quota double-counting, and `CURRENT_DATE` anchoring.
- [x] Bootstrap runs from a fresh clone (relative paths, keys and indexes).
- [x] Web dashboard with the five report pages (`dashboard/app.py`).
- [x] Portfolio screenshots saved in `screenshots/` (`01`–`05`).

## Remaining (Manual)

- [ ] Build the Power BI report pages using `powerbi/connection_guide.md`.
- [ ] Publish report to Power BI Service and verify refresh settings.
