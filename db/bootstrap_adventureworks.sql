CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS production;
CREATE SCHEMA IF NOT EXISTS person;
CREATE SCHEMA IF NOT EXISTS humanresources;
CREATE SCHEMA IF NOT EXISTS purchasing;

DROP TABLE IF EXISTS sales.sales_order_header;
CREATE TABLE sales.sales_order_header (
    sales_order_id int,
    revision_number int,
    order_date timestamp,
    due_date timestamp,
    ship_date timestamp,
    status int,
    online_order_flag boolean,
    sales_order_number text,
    purchase_order_number text,
    account_number text,
    customer_id int,
    sales_person_id int,
    territory_id int,
    bill_to_address_id int,
    ship_to_address_id int,
    ship_method_id int,
    credit_card_id int,
    credit_card_approval_code text,
    currency_rate_id int,
    sub_total numeric,
    tax_amt numeric,
    freight numeric,
    total_due numeric,
    comment text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS sales.sales_order_detail;
CREATE TABLE sales.sales_order_detail (
    sales_order_id int,
    sales_order_detail_id int,
    carrier_tracking_number text,
    order_qty numeric,
    product_id int,
    special_offer_id int,
    unit_price numeric,
    unit_price_discount numeric,
    line_total numeric,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS sales.sales_person;
CREATE TABLE sales.sales_person (
    business_entity_id int,
    territory_id int,
    sales_quota numeric,
    bonus numeric,
    commission_pct numeric,
    sales_ytd numeric,
    sales_last_year numeric,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS sales.sales_person_quota_history;
CREATE TABLE sales.sales_person_quota_history (
    business_entity_id int,
    quota_date timestamp,
    sales_quota numeric,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS sales.sales_territory;
CREATE TABLE sales.sales_territory (
    territory_id int,
    name text,
    country_region_code text,
    "group" text,
    sales_ytd numeric,
    sales_last_year numeric,
    cost_ytd numeric,
    cost_last_year numeric,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS sales.customer;
CREATE TABLE sales.customer (
    customer_id int,
    person_id int,
    store_id int,
    territory_id int,
    account_number text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS person.person;
CREATE TABLE person.person (
    business_entity_id int,
    person_type text,
    name_style int,
    title text,
    first_name text,
    middle_name text,
    last_name text,
    suffix text,
    email_promotion int,
    additional_contact_info text,
    demographics text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS person.email_address;
CREATE TABLE person.email_address (
    business_entity_id int,
    email_address_id int,
    email_address text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS person.business_entity_address;
CREATE TABLE person.business_entity_address (
    business_entity_id int,
    address_id int,
    address_type_id int,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS person.address;
CREATE TABLE person.address (
    address_id int,
    address_line1 text,
    address_line2 text,
    city text,
    state_province_id int,
    postal_code text,
    spatial_location text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS person.state_province;
CREATE TABLE person.state_province (
    state_province_id int,
    state_province_code text,
    country_region_code text,
    is_only_state_province_flag boolean,
    name text,
    territory_id int,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS production.product;
CREATE TABLE production.product (
    product_id int,
    name text,
    product_number text,
    make_flag boolean,
    finished_goods_flag boolean,
    color text,
    safety_stock_level int,
    reorder_point int,
    standard_cost numeric,
    list_price numeric,
    size text,
    size_unit_measure_code text,
    weight_unit_measure_code text,
    weight numeric,
    days_to_manufacture int,
    product_line text,
    class text,
    style text,
    product_subcategory_id int,
    product_model_id int,
    sell_start_date timestamp,
    sell_end_date timestamp,
    discontinued_date timestamp,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS production.product_subcategory;
CREATE TABLE production.product_subcategory (
    product_subcategory_id int,
    product_category_id int,
    name text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS production.product_category;
CREATE TABLE production.product_category (
    product_category_id int,
    name text,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS humanresources.employee;
CREATE TABLE humanresources.employee (
    business_entity_id int,
    national_id_number text,
    login_id text,
    organization_node text,
    organization_level text,
    job_title text,
    birth_date date,
    marital_status text,
    gender text,
    hire_date date,
    salaried_flag boolean,
    vacation_hours int,
    sick_leave_hours int,
    current_flag boolean,
    rowguid text,
    modified_date timestamp
);

DROP TABLE IF EXISTS humanresources.employee_department_history;
CREATE TABLE humanresources.employee_department_history (
    business_entity_id int,
    department_id int,
    shift_id int,
    start_date date,
    end_date date,
    modified_date timestamp
);

DROP TABLE IF EXISTS humanresources.department;
CREATE TABLE humanresources.department (
    department_id int,
    name text,
    group_name text,
    modified_date timestamp
);

DROP TABLE IF EXISTS humanresources.employee_pay_history;
CREATE TABLE humanresources.employee_pay_history (
    business_entity_id int,
    rate_change_date timestamp,
    rate numeric,
    pay_frequency int,
    modified_date timestamp
);

DROP TABLE IF EXISTS stg_sales_order_header;
CREATE TEMP TABLE stg_sales_order_header (
    c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text,c11 text,c12 text,c13 text,
    c14 text,c15 text,c16 text,c17 text,c18 text,c19 text,c20 text,c21 text,c22 text,c23 text,c24 text,c25 text,c26 text
);
\copy stg_sales_order_header FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/SalesOrderHeader.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.sales_order_header
SELECT c1::int,c2::int,c3::timestamp,c4::timestamp,c5::timestamp,c6::int,(c7='1'),c8,c9,c10,c11::int,NULLIF(c12,'')::int,NULLIF(c13,'')::int,
       c14::int,c15::int,c16::int,NULLIF(c17,'')::int,NULLIF(c18,''),NULLIF(c19,'')::int,c20::numeric,c21::numeric,c22::numeric,c23::numeric,NULLIF(c24,''),c25,c26::timestamp
FROM stg_sales_order_header;

DROP TABLE IF EXISTS stg_sales_order_detail;
CREATE TEMP TABLE stg_sales_order_detail (
    c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text,c11 text
);
\copy stg_sales_order_detail FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/SalesOrderDetail.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.sales_order_detail
SELECT c1::int,c2::int,NULLIF(c3,''),c4::numeric,c5::int,c6::int,c7::numeric,c8::numeric,c9::numeric,c10,c11::timestamp
FROM stg_sales_order_detail;

DROP TABLE IF EXISTS stg_sales_person;
CREATE TEMP TABLE stg_sales_person (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text);
\copy stg_sales_person FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/SalesPerson.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.sales_person
SELECT c1::int,NULLIF(c2,'')::int,NULLIF(c3,'')::numeric,c4::numeric,c5::numeric,c6::numeric,c7::numeric,c8,c9::timestamp
FROM stg_sales_person;

DROP TABLE IF EXISTS stg_sales_person_quota_history;
CREATE TEMP TABLE stg_sales_person_quota_history (c1 text,c2 text,c3 text,c4 text,c5 text);
\copy stg_sales_person_quota_history FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/SalesPersonQuotaHistory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.sales_person_quota_history
SELECT c1::int,c2::timestamp,c3::numeric,c4,c5::timestamp
FROM stg_sales_person_quota_history;

DROP TABLE IF EXISTS stg_sales_territory;
CREATE TEMP TABLE stg_sales_territory (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text);
\copy stg_sales_territory FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/SalesTerritory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.sales_territory
SELECT c1::int,c2,c3,c4,c5::numeric,c6::numeric,c7::numeric,c8::numeric,c9,c10::timestamp
FROM stg_sales_territory;

DROP TABLE IF EXISTS stg_customer;
CREATE TEMP TABLE stg_customer (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text);
\copy stg_customer FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Customer.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO sales.customer
SELECT c1::int,NULLIF(c2,'')::int,NULLIF(c3,'')::int,NULLIF(c4,'')::int,c5,c6,c7::timestamp
FROM stg_customer;

DROP TABLE IF EXISTS stg_person;
CREATE TEMP TABLE stg_person (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text,c11 text,c12 text,c13 text);
\copy stg_person FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Person.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO person.person
SELECT c1::int,c2,c3::int,NULLIF(c4,''),c5,NULLIF(c6,''),c7,NULLIF(c8,''),c9::int,NULLIF(c10,''),NULLIF(c11,''),c12,c13::timestamp
FROM stg_person;

DROP TABLE IF EXISTS stg_email_address;
CREATE TEMP TABLE stg_email_address (c1 text,c2 text,c3 text,c4 text,c5 text);
\copy stg_email_address FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/EmailAddress.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO person.email_address
SELECT c1::int,c2::int,NULLIF(c3,''),c4,c5::timestamp
FROM stg_email_address;

DROP TABLE IF EXISTS stg_business_entity_address;
CREATE TEMP TABLE stg_business_entity_address (c1 text,c2 text,c3 text,c4 text,c5 text);
\copy stg_business_entity_address FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/BusinessEntityAddress.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO person.business_entity_address
SELECT c1::int,c2::int,c3::int,c4,c5::timestamp
FROM stg_business_entity_address;

DROP TABLE IF EXISTS stg_address;
CREATE TEMP TABLE stg_address (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text);
\copy stg_address FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Address.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO person.address
SELECT c1::int,c2,NULLIF(c3,''),c4,c5::int,c6,NULLIF(c7,''),c8,c9::timestamp
FROM stg_address;

DROP TABLE IF EXISTS stg_state_province;
CREATE TEMP TABLE stg_state_province (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text);
\copy stg_state_province FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/StateProvince.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO person.state_province
SELECT c1::int,c2,c3,(c4='1'),c5,c6::int,c7,c8::timestamp
FROM stg_state_province;

DROP TABLE IF EXISTS stg_product;
CREATE TEMP TABLE stg_product (
    c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text,c11 text,c12 text,c13 text,
    c14 text,c15 text,c16 text,c17 text,c18 text,c19 text,c20 text,c21 text,c22 text,c23 text,c24 text,c25 text
);
\copy stg_product FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Product.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO production.product
SELECT
    c1::int,c2,c3,(c4='1'),(c5='1'),NULLIF(c6,''),c7::int,c8::int,c9::numeric,c10::numeric,NULLIF(c11,''),NULLIF(c12,''),NULLIF(c13,''),
    NULLIF(c14,'')::numeric,c15::int,NULLIF(c16,''),NULLIF(c17,''),NULLIF(c18,''),NULLIF(c19,'')::int,NULLIF(c20,'')::int,
    c21::timestamp,NULLIF(c22,'')::timestamp,NULLIF(c23,'')::timestamp,c24,c25::timestamp
FROM stg_product;

DROP TABLE IF EXISTS stg_product_subcategory;
CREATE TEMP TABLE stg_product_subcategory (c1 text,c2 text,c3 text,c4 text,c5 text);
\copy stg_product_subcategory FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/ProductSubcategory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO production.product_subcategory
SELECT c1::int,c2::int,c3,c4,c5::timestamp
FROM stg_product_subcategory;

DROP TABLE IF EXISTS stg_product_category;
CREATE TEMP TABLE stg_product_category (c1 text,c2 text,c3 text,c4 text);
\copy stg_product_category FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/ProductCategory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO production.product_category
SELECT c1::int,c2,c3,c4::timestamp
FROM stg_product_category;

DROP TABLE IF EXISTS stg_employee;
CREATE TEMP TABLE stg_employee (
    c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text
);
\copy stg_employee FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Employee.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO humanresources.employee
SELECT
    c1::int,c2,c3,NULLIF(c4,''),NULLIF(c5,''),c6,c7::date,c8,c9,c10::date,(c11='1'),c12::int,c13::int,(c14='1'),c15,c16::timestamp
FROM stg_employee;

DROP TABLE IF EXISTS stg_employee_department_history;
CREATE TEMP TABLE stg_employee_department_history (c1 text,c2 text,c3 text,c4 text,c5 text,c6 text);
\copy stg_employee_department_history FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/EmployeeDepartmentHistory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO humanresources.employee_department_history
SELECT c1::int,c2::int,c3::int,c4::date,NULLIF(c5,'')::date,c6::timestamp
FROM stg_employee_department_history;

DROP TABLE IF EXISTS stg_department;
CREATE TEMP TABLE stg_department (c1 text,c2 text,c3 text,c4 text);
\copy stg_department FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/Department.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO humanresources.department
SELECT c1::int,c2,c3,c4::timestamp
FROM stg_department;

DROP TABLE IF EXISTS stg_employee_pay_history;
CREATE TEMP TABLE stg_employee_pay_history (c1 text,c2 text,c3 text,c4 text,c5 text);
\copy stg_employee_pay_history FROM 'c:/Users/vaibh/OneDrive/Desktop/AdventureWorks-oltp/adventureworks-bi/tmp/EmployeePayHistory.tsv' WITH (FORMAT text, DELIMITER E'\t', NULL '')
INSERT INTO humanresources.employee_pay_history
SELECT c1::int,c2::timestamp,c3::numeric,c4::int,c5::timestamp
FROM stg_employee_pay_history;
