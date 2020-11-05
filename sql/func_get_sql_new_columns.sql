-- FUNCTION: public.func_get_sql_create_journal(bigint, integer)

-- DROP FUNCTION public.func_get_sql_create_journal(bigint, integer);

CREATE OR REPLACE FUNCTION public.func_get_sql_new_columns(
	id_jur bigint,
	flag_buffer integer DEFAULT 1)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE journal_stage_table_name0 varchar(500);
DECLARE tmp_result character varying DEFAULT '';
DECLARE cols RECORD;
begin
	-- stage table of journal
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.id_jur=$1);
	-- buffer or journal
	if flag_buffer=1 then
		-- so its buffer, correct name of stage table
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;
	
	for cols in 
		select	-- name of journal column with type for create table
				j.column_name||' '||
			(	case 	
				 	when j.id_account is NOT NULL or a1.type_value='float'
			   			then	'float' 
			   		when a1.type_value='string'
			   			then	'character varying' 
			   		when a1.type_value='date'
			   			then	'timestamp' 			   
			   		else 'character varying'
			  	end	) column_name_with_type,
				j.column_name
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1 and
				-- doesnt exists in current table
				not exists	(	select	1
								from	information_schema.columns c
								where	c.column_name=j.column_name and
										c.table_name=journal_stage_table_name0 and
										c.table_schema='public'	)
		union all
		-- add technical columns
		--select * from information_schema.columns
		select	
				j.column_name||' '||
			(	case 	
				 	when j.column_name='_pk_num'
			   			then	'bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key' 
			 		when j.column_name='flag_technical_storno'
			   			then	'integer NOT NULL DEFAULT 0' 
			 		when j.column_name='_pk_num_link_from_storno'
			   			then	'bigint references '||journal_stage_table_name0||'(_pk_num)'			 
			 		when j.column_name='hash_key'
			   			then	'character varying(32) NOT NULL DEFAULT '''	
			 		when j.column_name='id_hash_log'
			   			then	'bigint references public._config_journals_hash_log(id_hash_log)'				 
			 		when j.column_name='id_log'
			   			then	'bigint references public._config_journals_log(id_log)'
			 		when j.column_name='id_src'
			   			then	'bigint references public._config_sources(id_src)'			 
			  	end	) column_name_with_type,
				j.column_name
		from	(	select	j1.column_name
				 	from	public.view_technical_column_of_journals j1
					where	flag_buffer=0
				 	union all
				 	select	j1.column_name
				 	from	public.view_technical_column_of_journals_buffer j1
					where	flag_buffer=1	) j
		where	-- doesnt exists in current table
				not exists	(	select	1
								from	information_schema.columns c
								where	c.column_name=j.column_name and
										c.table_name=journal_stage_table_name0 and
										c.table_schema='public'	)		
	loop
		-- list of columns for alter table 
		tmp_result=tmp_result||(case when tmp_result='' then '' else '; ' end)||'alter table '||journal_stage_table_name0||' add '||cols.column_name_with_type;
	end loop;
	-- return result
	return tmp_result;
end
$BODY$;


