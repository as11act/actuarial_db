-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.2
-- PostgreSQL version: 12.0
-- Project Site: pgmodeler.io
-- Model Author: ---


-- Database creation must be done outside a multicommand file.
-- These commands were put in this file only as a convenience.
-- -- object: new_database | type: DATABASE --
-- -- DROP DATABASE IF EXISTS new_database;
-- CREATE DATABASE new_database;
-- -- ddl-end --
-- 

-- object: public._config_journals | type: TABLE --
-- DROP TABLE IF EXISTS public._config_journals CASCADE;
CREATE TABLE public._config_journals (
	id_jur bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	journal_name varchar(500) NOT NULL,
	CONSTRAINT _config_journals_pk PRIMARY KEY (id_jur)

);
-- ddl-end --
COMMENT ON TABLE public._config_journals IS E'Configuration table of meta-data of journals';
-- ddl-end --
-- ALTER TABLE public._config_journals OWNER TO postgres;
-- ddl-end --

-- object: public._config_journal_columns | type: TABLE --
-- DROP TABLE IF EXISTS public._config_journal_columns CASCADE;
CREATE TABLE public._config_journal_columns (
	id_col bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_jur bigint NOT NULL,
	column_name varchar(500) NOT NULL,
	id_account bigint,
	id_analytic bigint,
	CONSTRAINT _config_journal_columns_pk PRIMARY KEY (id_col)

);
-- ddl-end --
-- ALTER TABLE public._config_journal_columns OWNER TO postgres;
-- ddl-end --

-- object: public._config_accounts | type: TABLE --
-- DROP TABLE IF EXISTS public._config_accounts CASCADE;
CREATE TABLE public._config_accounts (
	id_account bigint NOT NULL,
	account_name varchar(500) NOT NULL,
	CONSTRAINT _config_accounts_pk PRIMARY KEY (id_account)

);
-- ddl-end --
-- ALTER TABLE public._config_accounts OWNER TO postgres;
-- ddl-end --

-- object: public._config_analytics | type: TABLE --
-- DROP TABLE IF EXISTS public._config_analytics CASCADE;
CREATE TABLE public._config_analytics (
	id_analytic bigint NOT NULL,
	analytic_name varchar(500) NOT NULL,
	CONSTRAINT _config_analytic_pk PRIMARY KEY (id_analytic)

);
-- ddl-end --
-- ALTER TABLE public._config_analytics OWNER TO postgres;
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


