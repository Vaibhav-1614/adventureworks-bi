-- AdventureWorks BI schema and access bootstrap

CREATE SCHEMA IF NOT EXISTS bi;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'powerbi_reader') THEN
        CREATE ROLE powerbi_reader
            LOGIN
            PASSWORD '<POWERBI_READER_PASSWORD>';
    END IF;
END
$$;

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

CREATE OR REPLACE FUNCTION bi.days_between(start_date date, end_date date)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (end_date - start_date)::int;
$$;
