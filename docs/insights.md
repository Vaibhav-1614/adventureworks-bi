# AdventureWorks BI Insights

Data source: `adventureworks-bi/tmp/*.tsv` files prepared from AdventureWorks OLTP exports.

## Insight 1

- Observation: Revenue concentration is strongest in North America, led by Southwest territory.
- Evidence: Top territory revenue totals are Southwest (`24.18M`), Canada (`16.36M`), and Northwest (`16.08M`), all in North America.
- Impact: Regional performance is heavily concentrated, creating dependency risk if top territories slow down.
- Action: Set territory-level stretch targets in top markets while accelerating pipeline development in lower-contributing regions.

## Insight 2

- Observation: Mountain-200 variants dominate product-level sales contribution.
- Evidence: Top five SKUs by line revenue are all Mountain-200 models, each contributing `3.43M` to `4.40M` in revenue.
- Impact: Product mix risk increases when a single family drives a disproportionate share of revenue.
- Action: Protect Mountain-200 availability and margin while testing cross-sell bundles that raise sales share for non-dominant categories.

## Insight 3

- Observation: Digital channel is meaningful but still secondary to offline revenue.
- Evidence: Online orders contribute `26.73%` of subtotal revenue across the full dataset.
- Impact: There is room to expand online acquisition and conversion without threatening the core offline channel.
- Action: Launch focused online promotions in top territories and monitor monthly online share lift.

## Insight 4

- Observation: The latest month shows a sharp revenue drop likely due to an incomplete period.
- Evidence: Revenue declines from `1.91M` in `2025-05` to `47.49K` in `2025-06` (`-97.51%` MoM) while orders remain present.
- Impact: Using partial-month data in executive KPIs can trigger false alerts and poor decisions.
- Action: Add a report-level "complete month only" filter or a KPI warning badge for incomplete months.
