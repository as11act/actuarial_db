-- Diff code generated with pgModeler (PostgreSQL Database Modeler)
-- pgModeler version: 0.9.3-beta1
-- Diff date: 2020-11-03 10:58:45
-- Source model: db_journals
-- Database: db_journals
-- PostgreSQL version: 12.0

-- [ Diff summary ]
-- Dropped objects: 3
-- Created objects: 1
-- Changed objects: 0
-- Truncated tables: 0

SET search_path=public,pg_catalog;
-- ddl-end --


-- [ Dropped objects ] --
DROP FUNCTION IF EXISTS public.func_get_sql_create_buffer(bigint) CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data2 CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data1 CASCADE;
-- ddl-end --


-- [ Created objects ] --
-- object: journal_stage_table_name | type: COLUMN --
-- ALTER TABLE public._config_journals DROP COLUMN IF EXISTS journal_stage_table_name CASCADE;
ALTER TABLE public._config_journals ADD COLUMN journal_stage_table_name varchar(1000) GENERATED ALWAYS AS ('stage_'||replace(lower(journal_name),' ','_')) STORED;
-- ddl-end --


