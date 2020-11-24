-- FUNCTION: public.func_get_sql_insert_buffer(bigint, bigint, bigint)

-- DROP FUNCTION public.func_get_sql_insert_buffer(bigint, bigint, bigint);

CREATE OR REPLACE FUNCTION public.func_get_sql_insert_buffer(
	id_jur0 bigint,
	id_log0 bigint,
	id_hash_log0 bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE journal_stage_table_name0 character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_list_cols character varying DEFAULT '';
DECLARE id_src_prev bigint;
DECLARE id_condition0 bigint;
DECLARE sql_condition_prev character varying DEFAULT '';
DECLARE db_name_prev character varying DEFAULT '';
DECLARE schema_name_prev character varying DEFAULT '';
DECLARE table_name_prev character varying DEFAULT '';
DECLARE sql_hash_key_prev character varying DEFAULT '';
DECLARE src_cols RECORD;
begin
	-- journal stage table
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.id_jur=$1);
	-- so, buffer table is
	journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	-- condition_id
	id_condition0=(select c.condition_id from public._config_journals_log c where c.id_log=id_log0);
	-- create list of cols
	/*	loop on all journal columns	*/
	for src_cols in
		select	jc.column_name
		from	public._config_journals j 
				inner join public._config_journal_columns jc on jc.id_jur=j.id_jur
		where	j.id_jur=$1
		order by jc.column_name
	loop
		sql_list_cols=sql_list_cols||(case when sql_list_cols='' then '' else ',' end)||src_cols.column_name;
	end loop;	
	-- add technical columns
	sql_list_cols=sql_list_cols||',id_src,id_log,id_hash_log,hash_key';

	/*	loop on all source columns	*/
	for src_cols in 
		select	s.id_src,
				s.db_name,
				s.schema_name,
				s.table_name,
				sc.column_name column_name_src
		from	-- link columns journal-source
				public._config_journal_column_match_source_column jcm
				-- our journal columns
				inner join public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur and jc.id_jur=$1
				-- sources column for journal
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src
				-- sources 
				inner join public._config_sources s on s.id_src=sc.id_src
		order by s.id_src,jc.column_name
	loop
		-- generate sql to insert sources
		sql_text=sql_text||(	case
									-- it's first row of id_src -> insert into 
									when id_src_prev is NULL then 'insert into '||journal_stage_table_name0||'('||sql_list_cols||') select '||src_cols.column_name_src
									-- it's new row of id_src -> insert into 
									when id_src_prev<>src_cols.id_src then ','||cast(id_src_prev as character varying)||' id_src,'||cast($2 as character varying)||' id_log,'||cast($3 as character varying)||' id_hash_log,'||sql_hash_key_prev||' hash_key from '||db_name_prev||'.'||schema_name_prev||'.'||table_name_prev||' where '||sql_condition_prev||'; insert into '||journal_stage_table_name0||'('||sql_list_cols||') select '||src_cols.column_name_src
									-- other cases
									else ','||src_cols.column_name_src
								end	);			
								
		-- create prev values
		id_src_prev=src_cols.id_src;
		db_name_prev=src_cols.db_name;
		schema_name_prev=src_cols.schema_name;
		table_name_prev=src_cols.table_name;
		sql_hash_key_prev=public.func_get_sql_hash_key_for_source(id_hash_log0, src_cols.id_src);
		-- for conditon NULL replace with full condition 1=1
		sql_condition_prev=coalesce(public."func_get_SQL_of_condition_id_for_journal_for_source"(id_condition0, id_jur0, id_src_prev),'(1=1)');
	end loop;
	-- truncate buffer table first
	sql_text='truncate table '||journal_stage_table_name0||'; '||sql_text;
	-- for the last source we should add technical columns and section from
	sql_text=sql_text||','||cast(src_cols.id_src as character varying)||' id_src,'||cast($2 as character varying)||' id_log,'||cast($3 as character varying)||' id_hash_log,'||sql_hash_key_prev||' hash_key from '||db_name_prev||'.'||schema_name_prev||'.'||table_name_prev||' where '||sql_condition_prev||';';
	
	return sql_text;
end
$BODY$;

ALTER FUNCTION public.func_get_sql_insert_buffer(bigint, bigint, bigint)
    OWNER TO postgres;
