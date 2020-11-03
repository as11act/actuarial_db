/*
SELECT public.func_get_sql_create_buffer(
	1, 
	0
)*/

create table stage_insurance_premium_journal(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,d_opr timestamp,
					id_contract character varying,
					id_risk character varying,
					gwp float,flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references stage_insurance_premium_journal(_pk_num),
				id_load_log bigint,
					--hash_key character varying(32) NOT NULL GENERATED ALWAYS AS (md5(lower(coalesce(cast(d_opr as character varying),'cNULL')))) STORED
					hash_key character varying(32) NOT NULL GENERATED ALWAYS AS (md5(lower(coalesce(to_char(d_opr,'MON-DD-YYYY HH12:MIPM'),'cNULL')))) STORED
											)

/*
create table stage_insurance_premium_journal(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,d_opr timestamp,
					id_contract character varying,
					id_risk character varying,
					gwp float,flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references stage_insurance_premium_journal(_pk_num),id_load_log bigint,hash_key character varying(32) NOT NULL GENERATED ALWAYS AS (md5(lower(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(id_contract as character varying),'cNULL')||coalesce(cast(id_risk as character varying),'cNULL')||coalesce(cast(gwp as character varying),'cNULL')))) STORED)

*/
/*
create table stage_insurance_premium_journal(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,d_opr timestamp,
					id_contract character varying,
					id_risk character varying,
					gwp float,flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references stage_insurance_premium_journal(_pk_num),
											 id_load_log bigint,
	hash_key character varying(32) NOT NULL GENERATED ALWAYS AS (md5(	'hello'	)) STORED
				)
				
select	md5(	'hello'	)				
*/
-- journal_stage_table_name character varying(1000) COLLATE pg_catalog."default" GENERATED ALWAYS AS (('stage_'::text || replace(lower((journal_name)::text), ' '::text, '_'::text))) STORED				

/*
create table stage_insurance_premium_journal(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,d_opr timestamp,
					id_contract character varying,
					id_risk character varying,
					gwp float,flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references stage_insurance_premium_journal(_pk_num),
											 id_load_log bigint,
	hash_key character varying(32) NOT NULL GENERATED ALWAYS AS md5(	lower(		coalesce(cast(d_opr as character varying),'cNULL')||
																			  		coalesce(cast(id_contract as character varying),'cNULL')||
																			  		coalesce(cast(id_risk as character varying),'cNULL')||
																			  		coalesce(cast(gwp as character varying),'cNULL')	)	) STORED
				)
*/				
--md5(lower(coalesce(cast(d_opr as character varying),'cNULL')||coalesce(cast(id_contract as character varying),'cNULL')||coalesce(cast(id_risk as character varying),'cNULL')||coalesce(cast(gwp as character varying),'cNULL')))				