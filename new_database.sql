-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.3-beta1
-- PostgreSQL version: 13.0
-- Project Site: pgmodeler.io
-- Model Author: Andrey Suvorov

-- Database creation must be performed outside a multi lined SQL file. 
-- These commands were put in this file only as a convenience.
-- 
-- object: db_journals | type: DATABASE --
-- DROP DATABASE IF EXISTS db_journals;
CREATE DATABASE db_journals;
-- ddl-end --
COMMENT ON DATABASE db_journals IS E'Database with journals';
-- ddl-end --


-- object: public._config_journals | type: TABLE --
-- DROP TABLE IF EXISTS public._config_journals CASCADE;
CREATE TABLE public._config_journals (
	id_jur bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	journal_name varchar(500) NOT NULL,
	CONSTRAINT _config_journals_pk PRIMARY KEY (id_jur)

);
-- ddl-end --
COMMENT ON TABLE public._config_journals IS E'Configuration table: list of journals';
-- ddl-end --
ALTER TABLE public._config_journals OWNER TO postgres;
-- ddl-end --

-- object: public._config_journal_columns | type: TABLE --
-- DROP TABLE IF EXISTS public._config_journal_columns CASCADE;
CREATE TABLE public._config_journal_columns (
	id_col_jur bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_jur bigint NOT NULL,
	column_name varchar(500) NOT NULL,
	id_account bigint,
	id_analytic bigint,
	CONSTRAINT _config_journal_columns_pk PRIMARY KEY (id_col_jur),
	CONSTRAINT _check_config_journals_id_analytic_account CHECK (id_account is not NULL and id_analytic is NULL or id_account is NULL and id_analytic is not NULL)

);
-- ddl-end --
COMMENT ON TABLE public._config_journal_columns IS E'Configuration table: columns of particular journal. Also each column has information about - analytic or account';
-- ddl-end --
ALTER TABLE public._config_journal_columns OWNER TO postgres;
-- ddl-end --

-- object: public._config_accounts | type: TABLE --
-- DROP TABLE IF EXISTS public._config_accounts CASCADE;
CREATE TABLE public._config_accounts (
	id_account bigint NOT NULL,
	account_name varchar(500) NOT NULL,
	finance_type varchar(500) NOT NULL,
	type_value varchar(500) NOT NULL,
	CONSTRAINT _config_accounts_pk PRIMARY KEY (id_account),
	CONSTRAINT ch_config_accounts_finance_type CHECK (finance_type in ('flow','reserve')),
	CONSTRAINT ch_config_accounts_type_value CHECK (type_value in ('float','string','date'))

);
-- ddl-end --
COMMENT ON COLUMN public._config_accounts.finance_type IS E'Finance type - flow or reserve';
-- ddl-end --
COMMENT ON COLUMN public._config_accounts.type_value IS E'Type of value of the column = float, string or date';
-- ddl-end --
ALTER TABLE public._config_accounts OWNER TO postgres;
-- ddl-end --

-- object: public._config_analytics | type: TABLE --
-- DROP TABLE IF EXISTS public._config_analytics CASCADE;
CREATE TABLE public._config_analytics (
	id_analytic bigint NOT NULL,
	analytic_name varchar(500) NOT NULL,
	CONSTRAINT _config_analytic_pk PRIMARY KEY (id_analytic)

);
-- ddl-end --
ALTER TABLE public._config_analytics OWNER TO postgres;
-- ddl-end --

-- object: public._config_source_columns | type: TABLE --
-- DROP TABLE IF EXISTS public._config_source_columns CASCADE;
CREATE TABLE public._config_source_columns (
	id_col_src bigint NOT NULL,
	id_src bigint NOT NULL,
	column_name varchar(500) NOT NULL,
	CONSTRAINT _config_journal_sources_pk PRIMARY KEY (id_col_src)

);
-- ddl-end --
COMMENT ON TABLE public._config_source_columns IS E'Columns of source data for journals';
-- ddl-end --
ALTER TABLE public._config_source_columns OWNER TO postgres;
-- ddl-end --

-- object: public._config_journal_column_match_source_column | type: TABLE --
-- DROP TABLE IF EXISTS public._config_journal_column_match_source_column CASCADE;
CREATE TABLE public._config_journal_column_match_source_column (
	id_col_jur bigint NOT NULL,
	id_col_src bigint NOT NULL,
	CONSTRAINT _config_journal_match_source_pk PRIMARY KEY (id_col_jur,id_col_src)

);
-- ddl-end --
COMMENT ON TABLE public._config_journal_column_match_source_column IS E'Match journal and sources';
-- ddl-end --
ALTER TABLE public._config_journal_column_match_source_column OWNER TO postgres;
-- ddl-end --

-- object: public._config_sources | type: TABLE --
-- DROP TABLE IF EXISTS public._config_sources CASCADE;
CREATE TABLE public._config_sources (
	id_src bigint NOT NULL,
	db_name varchar(500) NOT NULL,
	schema_name varchar(500) NOT NULL,
	table_name varchar(500) NOT NULL,
	CONSTRAINT _config_sources_pk PRIMARY KEY (id_src)

);
-- ddl-end --
COMMENT ON TABLE public._config_sources IS E'Sources of data';
-- ddl-end --
ALTER TABLE public._config_sources OWNER TO postgres;
-- ddl-end --

-- object: fk_config_journal_columns_id_jur | type: CONSTRAINT --
-- ALTER TABLE public._config_journal_columns DROP CONSTRAINT IF EXISTS fk_config_journal_columns_id_jur CASCADE;
ALTER TABLE public._config_journal_columns ADD CONSTRAINT fk_config_journal_columns_id_jur FOREIGN KEY (id_jur)
REFERENCES public._config_journals (id_jur) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_config_journal_columns_id_account | type: CONSTRAINT --
-- ALTER TABLE public._config_journal_columns DROP CONSTRAINT IF EXISTS fk_config_journal_columns_id_account CASCADE;
ALTER TABLE public._config_journal_columns ADD CONSTRAINT fk_config_journal_columns_id_account FOREIGN KEY (id_account)
REFERENCES public._config_accounts (id_account) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: _config_journal_columns_analytic | type: CONSTRAINT --
-- ALTER TABLE public._config_journal_columns DROP CONSTRAINT IF EXISTS _config_journal_columns_analytic CASCADE;
ALTER TABLE public._config_journal_columns ADD CONSTRAINT _config_journal_columns_analytic FOREIGN KEY (id_analytic)
REFERENCES public._config_analytics (id_analytic) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_config_journal_sources_id_src | type: CONSTRAINT --
-- ALTER TABLE public._config_source_columns DROP CONSTRAINT IF EXISTS fk_config_journal_sources_id_src CASCADE;
ALTER TABLE public._config_source_columns ADD CONSTRAINT fk_config_journal_sources_id_src FOREIGN KEY (id_src)
REFERENCES public._config_sources (id_src) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_config_journal_match_source_id_col_jur | type: CONSTRAINT --
-- ALTER TABLE public._config_journal_column_match_source_column DROP CONSTRAINT IF EXISTS fk_config_journal_match_source_id_col_jur CASCADE;
ALTER TABLE public._config_journal_column_match_source_column ADD CONSTRAINT fk_config_journal_match_source_id_col_jur FOREIGN KEY (id_col_jur)
REFERENCES public._config_journal_columns (id_col_jur) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_config_journal_match_source_id_col_src | type: CONSTRAINT --
-- ALTER TABLE public._config_journal_column_match_source_column DROP CONSTRAINT IF EXISTS fk_config_journal_match_source_id_col_src CASCADE;
ALTER TABLE public._config_journal_column_match_source_column ADD CONSTRAINT fk_config_journal_match_source_id_col_src FOREIGN KEY (id_col_src)
REFERENCES public._config_source_columns (id_col_src) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --


