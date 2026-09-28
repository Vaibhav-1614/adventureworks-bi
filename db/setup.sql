-- AdventureWorks BI schema and access bootstrap

CREATE SCHEMA IF NOT EXISTS bi;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'powerbi_reader') THEN
        CREATE ROLE powerbi_reader LOGIN;
    END IF;
END
$$;

-- Set the reader password without committing it to git:
--   psql ... -v powerbi_reader_password='...' -f db/setup.sql
\if :{?powerbi_reader_password}
ALTER ROLE powerbi_reader PASSWORD :'powerbi_reader_password';
\else
\echo 'powerbi_reader_password not provided; role created without a password (set one before connecting Power BI).'
\endif

GRANT USAGE ON SCHEMA sales, production, person, purchasing, humanresources, bi TO powerbi_reader;

GRANT SELECT ON ALL TABLES IN SCHEMA sales, production, person, purchasing, humanresources, bi TO powerbi_reader;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA sales, production, person, purchasing, humanresources, bi TO powerbi_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO powerbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA production GRANT SELECT ON TABLES TO powerbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA person GRANT SELECT ON TABLES TO powerbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA purchasing GRANT SELECT ON TABLES TO powerbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA humanresources GRANT SELECT ON TABLES TO powerbi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA bi GRANT SELECT ON TABLES TO powerbi_reader;

CREATE OR REPLACE FUNCTION bi.safe_divide(numerator numeric, denominator numeric)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN denominator IS NULL OR denominator = 0 THEN NULL
        ELSE numerator / denominator
    END;
$$;

-- Reference ("today") date for recency/tenure metrics. AdventureWorks is a historical
-- snapshot, so measuring against CURRENT_DATE would push every customer into the same
-- recency bucket and every employee into the same tenure band. Anchor to the last order date.
CREATE OR REPLACE FUNCTION bi.as_of_date()
RETURNS date
LANGUAGE sql
STABLE
AS $$
    SELECT MAX(order_date)::date FROM sales.sales_order_header;
$$;

CREATE OR REPLACE FUNCTION bi.days_between(start_date date, end_date date)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (end_date - start_date)::int;
$$;
