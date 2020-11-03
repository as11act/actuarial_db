-- Diff code generated with pgModeler (PostgreSQL Database Modeler)
-- pgModeler version: 0.9.3-beta1
-- Diff date: 2020-11-03 19:56:55
-- Source model: db_journals
-- Database: db_journals
-- PostgreSQL version: 12.0

-- [ Diff summary ]
-- Dropped objects: 4
-- Created objects: 3
-- Changed objects: 0
-- Truncated tables: 0

SET search_path=public,pg_catalog;
-- ddl-end --


-- [ Dropped objects ] --
DROP TABLE IF EXISTS public.stage_insurance_premium_journal CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.func_get_sql_create_buffer(bigint) CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data2 CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data1 CASCADE;
-- ddl-end --


-- [ Created objects ] --
-- object: account_description | type: COLUMN --
-- ALTER TABLE public._config_accounts DROP COLUMN IF EXISTS account_description CASCADE;
ALTER TABLE public._config_accounts ADD COLUMN account_description varchar(1000) ;
-- ddl-end --

COMMENT ON COLUMN public._config_accounts.account_description IS E'Description of account';
-- ddl-end --


-- object: analytic_column_name | type: COLUMN --
-- ALTER TABLE public._config_analytics DROP COLUMN IF EXISTS analytic_column_name CASCADE;
ALTER TABLE public._config_analytics ADD COLUMN analytic_column_name varchar(500) GENERATED ALWAYS AS (replace(lower(analytic_name),' ','_')) STORED;
-- ddl-end --

COMMENT ON COLUMN public._config_analytics.analytic_column_name IS E'Column name of analytic in stage journal';
-- ddl-end --


-- object: account_column_name | type: COLUMN --
-- ALTER TABLE public._config_accounts DROP COLUMN IF EXISTS account_column_name CASCADE;
ALTER TABLE public._config_accounts ADD COLUMN account_column_name varchar(500) GENERATED ALWAYS AS (replace(lower(account_name),' ','_')) STORED;
-- ddl-end --

COMMENT ON COLUMN public._config_accounts.account_column_name IS E'Column name of account to use in stage table journal';
-- ddl-end --


