-- Diff code generated with pgModeler (PostgreSQL Database Modeler)
-- pgModeler version: 0.9.3-beta1
-- Diff date: 2020-11-21 18:30:32
-- Source model: new_database
-- Database: db_journals
-- PostgreSQL version: 12.0

-- [ Diff summary ]
-- Dropped objects: 2
-- Created objects: 7
-- Changed objects: 1
-- Truncated tables: 0

SET search_path=public,pg_catalog;
-- ddl-end --


-- [ Dropped objects ] --
ALTER TABLE public._finance_function_pins DROP CONSTRAINT IF EXISTS _finance_function_pins_id_account_fkey CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public._config_accounts CASCADE;
-- ddl-end --
ALTER TABLE public._finance_function_parametres DROP COLUMN IF EXISTS parameter_value_float CASCADE;
-- ddl-end --
ALTER TABLE public._finance_function_parametres DROP COLUMN IF EXISTS parameter_value_string CASCADE;
-- ddl-end --


-- [ Created objects ] --
-- object: parameter_number | type: COLUMN --
-- ALTER TABLE public._finance_function_parametres DROP COLUMN IF EXISTS parameter_number CASCADE;
ALTER TABLE public._finance_function_parametres ADD COLUMN parameter_number integer NOT NULL;
-- ddl-end --


-- object: public._finance_block_parametres | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_block_parametres CASCADE;
CREATE TABLE public._finance_block_parametres (
	id_block_parameter bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_block bigint NOT NULL,
	parameter_number integer NOT NULL,
	parameter_value_float float,
	parameter_value_string varchar(2000),
	CONSTRAINT _finance_block_parametres_pk PRIMARY KEY (id_block_parameter)

);
-- ddl-end --
ALTER TABLE public._finance_block_parametres OWNER TO postgres;
-- ddl-end --

-- object: public._finance_config_storage_block_pins | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_config_storage_block_pins CASCADE;
CREATE TABLE public._finance_config_storage_block_pins (
	id_storage_pin bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_storage bigint NOT NULL,
	id_block_pin bigint NOT NULL,
	CONSTRAINT _finance_config_storage_block_pins_pk PRIMARY KEY (id_storage_pin)

);
-- ddl-end --
ALTER TABLE public._finance_config_storage_block_pins OWNER TO postgres;
-- ddl-end --

-- object: public._finance_config_storage_tables | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_config_storage_tables CASCADE;
CREATE TABLE public._finance_config_storage_tables (
	id_storage bigint NOT NULL,
	db_name varchar(500) NOT NULL,
	schema_name varchar(500) NOT NULL,
	table_name varchar(500) NOT NULL,
	CONSTRAINT _finance_config_storage_tables_pk PRIMARY KEY (id_storage)

);
-- ddl-end --
ALTER TABLE public._finance_config_storage_tables OWNER TO postgres;
-- ddl-end --



-- [ Changed objects ] --
COMMENT ON COLUMN public._finance_function_pins.pin_value_type IS E'Type of value pin = finance (account); number array (dim 1,2,..); string array (dim 1,2, ...); bus';
-- ddl-end --


-- [ Created foreign keys ] --
-- object: fk_finance_block_parametres_id_block | type: CONSTRAINT --
-- ALTER TABLE public._finance_block_parametres DROP CONSTRAINT IF EXISTS fk_finance_block_parametres_id_block CASCADE;
ALTER TABLE public._finance_block_parametres ADD CONSTRAINT fk_finance_block_parametres_id_block FOREIGN KEY (id_block)
REFERENCES public._finance_blocks (id_block) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_finance_config_storage_block_pins_id_storage | type: CONSTRAINT --
-- ALTER TABLE public._finance_config_storage_block_pins DROP CONSTRAINT IF EXISTS fk_finance_config_storage_block_pins_id_storage CASCADE;
ALTER TABLE public._finance_config_storage_block_pins ADD CONSTRAINT fk_finance_config_storage_block_pins_id_storage FOREIGN KEY (id_storage)
REFERENCES public._finance_config_storage_tables (id_storage) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_finance_config_storage_block_pins_id_block_pin | type: CONSTRAINT --
-- ALTER TABLE public._finance_config_storage_block_pins DROP CONSTRAINT IF EXISTS fk_finance_config_storage_block_pins_id_block_pin CASCADE;
ALTER TABLE public._finance_config_storage_block_pins ADD CONSTRAINT fk_finance_config_storage_block_pins_id_block_pin FOREIGN KEY (id_block_pin)
REFERENCES public._finance_block_pins (id_block_pin) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

