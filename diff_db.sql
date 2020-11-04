-- Diff code generated with pgModeler (PostgreSQL Database Modeler)
-- pgModeler version: 0.9.3-beta1
-- Diff date: 2020-11-04 11:46:41
-- Source model: db_journals
-- Database: db_journals
-- PostgreSQL version: 12.0

-- [ Diff summary ]
-- Dropped objects: 15
-- Created objects: 0
-- Changed objects: 3
-- Truncated tables: 0

SET search_path=public,pg_catalog;
-- ddl-end --


-- [ Dropped objects ] --
ALTER TABLE public.stage_insurance_premium_journal_buffer DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_buffer_id_hash_log_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal_buffer DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_buffer_id_src_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal_buffer DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_buffer_id_log_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_id_hash_log_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal__pk_num_link_from_storno_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_id_src_fkey CASCADE;
-- ddl-end --
ALTER TABLE public.stage_insurance_premium_journal DROP CONSTRAINT IF EXISTS stage_insurance_premium_journal_id_log_fkey CASCADE;
-- ddl-end --
ALTER TABLE public._config_analytics DROP CONSTRAINT IF EXISTS uq__config_analytics CASCADE;
-- ddl-end --
ALTER TABLE public._config_accounts DROP CONSTRAINT IF EXISTS uq__config_accounts CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.stage_insurance_premium_journal_buffer CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.stage_insurance_premium_journal CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public."func_get_SQL_of_condition_id"(bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.func_get_sql_create_buffer(bigint,integer) CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data2 CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.test_source_prem_data1 CASCADE;
-- ddl-end --
ALTER TABLE public._config_accounts DROP COLUMN IF EXISTS account_name CASCADE;
-- ddl-end --
ALTER TABLE public._config_accounts DROP COLUMN IF EXISTS account_column_name CASCADE;
-- ddl-end --
ALTER TABLE public._config_analytics DROP COLUMN IF EXISTS analytic_name CASCADE;
-- ddl-end --
ALTER TABLE public._config_analytics DROP COLUMN IF EXISTS analytic_column_name CASCADE;
-- ddl-end --


-- [ Changed objects ] --
ALTER TABLE public._config_accounts ALTER COLUMN account_description SET NOT NULL;
-- ddl-end --
ALTER TABLE public._config_conditions ALTER COLUMN analytic_value_float TYPE float;
-- ddl-end --
ALTER TABLE public._config_journals_hash_log ALTER COLUMN flag_journal_was_updated_by_hash SET DEFAULT 0;
-- ddl-end --
