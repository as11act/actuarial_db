-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.3-beta1
-- PostgreSQL version: 13.0
-- Project Site: pgmodeler.io
-- Model Author: ---

-- Database creation must be performed outside a multi lined SQL file. 
-- These commands were put in this file only as a convenience.
-- 
-- object: new_database | type: DATABASE --
-- DROP DATABASE IF EXISTS new_database;
--CREATE DATABASE new_database;
-- ddl-end --


-- object: public._finance_blocks | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_blocks CASCADE;
CREATE TABLE public._finance_blocks (
	id_block bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	block_name varchar(500) NOT NULL,
	id_function bigint NOT NULL,
	opertaion_mode varchar(500) NOT NULL,
	CONSTRAINT _finance_blocks_pk PRIMARY KEY (id_block)

);
-- ddl-end --
COMMENT ON COLUMN public._finance_blocks.opertaion_mode IS E'How to operate: manual, auto (when data come), on condition ...';
-- ddl-end --
ALTER TABLE public._finance_blocks OWNER TO postgres;
-- ddl-end --

-- object: public._finance_functions | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_functions CASCADE;
CREATE TABLE public._finance_functions (
	id_function bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	function_name varchar(500) NOT NULL,
	CONSTRAINT _finance_functions_pk PRIMARY KEY (id_function)

);
-- ddl-end --
ALTER TABLE public._finance_functions OWNER TO postgres;
-- ddl-end --

-- object: public._finance_function_pins | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_function_pins CASCADE;
CREATE TABLE public._finance_function_pins (
	id_function_pin bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_function bigint NOT NULL,
	pin_number integer NOT NULL,
	pin_name varchar(500) NOT NULL,
	type_in_out varchar(3) NOT NULL,
	pin_value_type varchar(500) NOT NULL,
	id_account bigint,
	CONSTRAINT _finance_function_pins_pk PRIMARY KEY (id_function_pin)

);
-- ddl-end --
COMMENT ON COLUMN public._finance_function_pins.pin_value_type IS E'Type of value pin = finance (account); number array (dim 1,2,..); string array (dim 1,2, ...); bus';
-- ddl-end --
ALTER TABLE public._finance_function_pins OWNER TO postgres;
-- ddl-end --

-- object: public._finance_block_pins | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_block_pins CASCADE;
CREATE TABLE public._finance_block_pins (
	id_block_pin bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_block bigint NOT NULL,
	pin_number integer NOT NULL,
	CONSTRAINT _finance_block_pins_pk PRIMARY KEY (id_block_pin)

);
-- ddl-end --
ALTER TABLE public._finance_block_pins OWNER TO postgres;
-- ddl-end --

-- object: public._finance_blocks_net | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_blocks_net CASCADE;
CREATE TABLE public._finance_blocks_net (
	id_net bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_block_pin_src bigint NOT NULL,
	id_block_pin_dst bigint NOT NULL,
	CONSTRAINT _finance_blocks_net_pk PRIMARY KEY (id_net)

);
-- ddl-end --
ALTER TABLE public._finance_blocks_net OWNER TO postgres;
-- ddl-end --

-- object: public._finance_function_parametres | type: TABLE --
-- DROP TABLE IF EXISTS public._finance_function_parametres CASCADE;
CREATE TABLE public._finance_function_parametres (
	id_function_param bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	id_function bigint NOT NULL,
	parameter_name varchar(500) NOT NULL,
	type_value_float_string varchar(500) NOT NULL,
	parameter_value_float float,
	parameter_value_string varchar(2000),
	CONSTRAINT _finance_function_parametres_pk PRIMARY KEY (id_function_param)

);
-- ddl-end --
ALTER TABLE public._finance_function_parametres OWNER TO postgres;
-- ddl-end --

-- object: _finance_blocks_id_function_of_block | type: CONSTRAINT --
-- ALTER TABLE public._finance_blocks DROP CONSTRAINT IF EXISTS _finance_blocks_id_function_of_block CASCADE;
ALTER TABLE public._finance_blocks ADD CONSTRAINT _finance_blocks_id_function_of_block FOREIGN KEY (id_function)
REFERENCES public._finance_functions (id_function) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: _finance_function_pins_id_function | type: CONSTRAINT --
-- ALTER TABLE public._finance_function_pins DROP CONSTRAINT IF EXISTS _finance_function_pins_id_function CASCADE;
ALTER TABLE public._finance_function_pins ADD CONSTRAINT _finance_function_pins_id_function FOREIGN KEY (id_function)
REFERENCES public._finance_functions (id_function) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: _finance_block_pins_id_block | type: CONSTRAINT --
-- ALTER TABLE public._finance_block_pins DROP CONSTRAINT IF EXISTS _finance_block_pins_id_block CASCADE;
ALTER TABLE public._finance_block_pins ADD CONSTRAINT _finance_block_pins_id_block FOREIGN KEY (id_block)
REFERENCES public._finance_blocks (id_block) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_finance_blocks_net_src | type: CONSTRAINT --
-- ALTER TABLE public._finance_blocks_net DROP CONSTRAINT IF EXISTS fk_finance_blocks_net_src CASCADE;
ALTER TABLE public._finance_blocks_net ADD CONSTRAINT fk_finance_blocks_net_src FOREIGN KEY (id_block_pin_src)
REFERENCES public._finance_block_pins (id_block_pin) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_finance_blocks_net_dst | type: CONSTRAINT --
-- ALTER TABLE public._finance_blocks_net DROP CONSTRAINT IF EXISTS fk_finance_blocks_net_dst CASCADE;
ALTER TABLE public._finance_blocks_net ADD CONSTRAINT fk_finance_blocks_net_dst FOREIGN KEY (id_block_pin_dst)
REFERENCES public._finance_block_pins (id_block_pin) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_finance_function_parametres_id_function | type: CONSTRAINT --
-- ALTER TABLE public._finance_function_parametres DROP CONSTRAINT IF EXISTS fk_finance_function_parametres_id_function CASCADE;
ALTER TABLE public._finance_function_parametres ADD CONSTRAINT fk_finance_function_parametres_id_function FOREIGN KEY (id_function)
REFERENCES public._finance_functions (id_function) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --


