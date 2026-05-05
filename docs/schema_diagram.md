# AdventureWorks BI Schema Guide (5-Minute Version)

This project uses the AdventureWorks PostgreSQL schemas as source data and creates analyst-ready views in the `bi` schema.

## What each schema contains

- `sales`: orders, order lines, customers, salespeople, territories, quotas
- `production`: products, subcategories, categories, cost/price attributes
- `person`: people, email, address, state/province, business entity bridge tables
- `humanresources`: employees, department history, pay history, departments
- `purchasing`: vendor and purchasing operations (not central to current BI views)
- `bi`: reporting views and helper functions for Power BI

## Core relationship map in plain English

1. **Orders and revenue**
   - `sales.sales_order_header` is one row per order (`sales_order_id` primary key).
   - `sales.sales_order_detail` is one row per order line.
   - Join: `sales_order_detail.sales_order_id = sales_order_header.sales_order_id`.
   - Revenue is calculated from order lines.

2. **Salesperson and territory**
   - `sales_order_header.sales_person_id` links to `sales.sales_person.business_entity_id`.
   - `sales_order_header.territory_id` links to `sales.sales_territory.territory_id`.
   - `sales.sales_person_quota_history` stores quotas by `business_entity_id` and `quota_date`.

3. **Products**
   - `sales_order_detail.product_id` links to `production.product.product_id`.
   - `product.product_subcategory_id` links to `production.product_subcategory`.
   - `product_subcategory.product_category_id` links to `production.product_category`.

4. **Customers**
   - `sales.sales_order_header.customer_id` links to `sales.customer.customer_id`.
   - Individual customer identity comes through `sales.customer.person_id -> person.person.business_entity_id`.
   - Contact/location enrichment uses `person.email_address`, `person.business_entity_address`, `person.address`, and `person.state_province`.

5. **Employees and HR**
   - `humanresources.employee.business_entity_id` links to `person.person.business_entity_id`.
   - Current department comes from `humanresources.employee_department_history` where `end_date IS NULL`.
   - Current pay is the latest row in `humanresources.employee_pay_history`.
   - Sales linkage is optional via `sales.sales_person.business_entity_id`.

## Primary keys you will use most

- `sales.sales_order_header`: `sales_order_id`
- `sales.sales_order_detail`: typically (`sales_order_id`, `sales_order_detail_id`)
- `sales.customer`: `customer_id`
- `sales.sales_person`: `business_entity_id`
- `sales.sales_territory`: `territory_id`
- `production.product`: `product_id`
- `production.product_subcategory`: `product_subcategory_id`
- `production.product_category`: `product_category_id`
- `person.person`: `business_entity_id`
- `person.address`: `address_id`
- `person.state_province`: `state_province_id`
- `humanresources.employee`: `business_entity_id`
- `humanresources.department`: `department_id`

## Why the `bi` schema exists

The `bi` schema separates reporting logic from source OLTP tables:

- easier permissions (`powerbi_reader` gets read-only access)
- consistent KPI formulas in one place
- cleaner Power BI import model (no need to expose all raw operational tables)
