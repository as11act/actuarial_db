-- FUNCTION: public.func_get_sql_insert_journal(bigint, bigint)

-- DROP FUNCTION public.func_get_sql_insert_journal(bigint, bigint);

CREATE OR REPLACE FUNCTION public.func_get_sql_insert_journal(
	id_jur0 bigint,
	id_log0 bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE journal_stage_table_name0 character varying;
DECLARE journal_stage_table_name0_buffer character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_list_cols character varying DEFAULT '';
DECLARE sql_list_cols_storno character varying DEFAULT '';
DECLARE id_condition0 bigint;
DECLARE sql_condition character varying DEFAULT '';
begin
	-- input parametres
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.id_jur=$1);
	journal_stage_table_name0_buffer=journal_stage_table_name0||'_buffer';
	id_condition0=(select condition_id from public._config_journals_log where id_log=$2);
	sql_condition=public."func_get_SQL_of_condition_id_for_journal"(id_condition0, $1);
	--sql_condition=replace(sql_condition,'''','''''');
	-- get list of columns
	sql_list_cols=public.func_get_sql_list_columns_of_journal($1,FALSE);
	-- ger list of columns where account values with (-1)*
	sql_list_cols_storno=public.func_get_sql_list_columns_of_journal($1,TRUE);
	
	/*
	raise notice 'journal_stage_table_name0: %',journal_stage_table_name0;
	raise notice 'journal_stage_table_name0_buffer: %',journal_stage_table_name0_buffer;
	raise notice 'id_condition0: %',id_condition0;
	raise notice 'sql_condition: %',sql_condition;
	raise notice 'sql_list_cols: %',sql_list_cols;
	raise notice 'sql_list_cols_storno: %',sql_list_cols_storno;*/
	
	sql_text='-- create temporty tables with hash_key and number
	create temp table tmp_target (_pk_num bigint not null,hash_key character varying(32) not null,rn bigint not null,primary key(hash_key,rn) );
	create temp table tmp_buffer (_pk_num bigint not null,hash_key character varying(32) not null,rn bigint not null,primary key(hash_key,rn) );
	-- indexies of temp tables
	create index ind_target_pk_num on tmp_target(_pk_num);
	create index ind_buffer_pk_num on tmp_buffer(_pk_num);
	
	-- insert data to target
	insert into tmp_target
	select	j._pk_num,j.hash_key,row_number() over(partition by j.hash_key order by j._pk_num) rn
	from	'||journal_stage_table_name0||' j
	where	j.flag_technical_storno=0 and
			j.flag_storno_by_other=0 and
			-- condition from id_log
			'||sql_condition||';
			
	-- insert data from buffer
	insert into tmp_buffer
	select	j._pk_num,j.hash_key,row_number() over(partition by j.hash_key order by j._pk_num) rn
	from	'||journal_stage_table_name0_buffer||' j;
	
	-- update increment journal
	insert into '||journal_stage_table_name0||' ('||sql_list_cols||',flag_technical_storno,_pk_num_link_from_storno,id_log,id_hash_log,hash_key,id_src)
	-- making storno for rows, which are not in buffer
	select	'||sql_list_cols_storno||',1,tt._pk_num,'||cast(id_log0 as character varying)||',j.id_hash_log,j.hash_key,j.id_src
	from	tmp_target tt
			left join '||journal_stage_table_name0||' j on j._pk_num=tt._pk_num
	where	not exists (	select	1
					   		from	tmp_buffer tb
					   		where	tt.hash_key=tb.hash_key and
					   				tt.rn=tb.rn	)
	union all
	-- add new rows
	select	'||sql_list_cols||',0,NULL,'||cast(id_log0 as character varying)||',j.id_hash_log,j.hash_key,j.id_src
	from	tmp_buffer tb
			left join '||journal_stage_table_name0_buffer||' j on j._pk_num=tb._pk_num
	where	not exists (	select	1
					   		from	tmp_target tt
					   		where	tt.hash_key=tb.hash_key and
					   				tt.rn=tb.rn	);									
									
	-- update rows which was storned
	update	'||journal_stage_table_name0||' j
	set		flag_storno_by_other=1,
			storned_by_id_log=j1.id_log
	from	'||journal_stage_table_name0||' j1
	where	j._pk_num=j1._pk_num_link_from_storno and 
			j1.flag_technical_storno=1 and
			j.flag_storno_by_other=0;
			
	drop table tmp_target;
	drop table tmp_buffer;';
	
	--raise notice 'sql_text: %',sql_text;
	-- return result SQL
	return sql_text;
end
$BODY$;

ALTER FUNCTION public.func_get_sql_insert_journal(bigint, bigint)
    OWNER TO postgres;
