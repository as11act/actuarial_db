-- FUNCTION: public.func_get_sql_create_buffer(bigint)

-- DROP FUNCTION public.func_get_sql_create_buffer(bigint);

CREATE OR REPLACE FUNCTION public.func_get_sql_create_buffer(
	id_jur bigint,
	flag_buffer integer DEFAULT 1)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE tmp_cols character varying DEFAULT '';
DECLARE tmp_cols1 character varying DEFAULT '';
DECLARE tmp_tb_name character varying;
DECLARE tmp_result character varying;
DECLARE cols RECORD;
begin
	for cols in 
		select	-- name of journal column
				coalesce(a1.analytic_column_name,a2.account_column_name)||' '||
			(	case 	
				 	when j.id_account is NOT NULL or a1.type_value='float'
			   			then	'float' 
			   		when a1.type_value='string'
			   			then	'character varying' 
			   		when a1.type_value='date'
			   			then	'timestamp' 			   
			   		else 'character varying'
			  	end	) column_name_with_type,
				coalesce(a1.analytic_column_name,a2.account_column_name) column_name
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1
	loop
		-- list of columns for create table 
		tmp_cols=tmp_cols||(case when tmp_cols='' then '' else ',
					' end)||cols.column_name_with_type;
		-- list of columns for HASH md5
		tmp_cols1=tmp_cols1||(case when tmp_cols1='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- journal_name + buffer prefix
	-- if its not buffer table = add additional columns
	tmp_tb_name=(select journal_stage_table_name from public._config_journals j where j.id_jur=$1);		
	tmp_cols1='md5(lower('||tmp_cols1||'))';
	if $2=0 then
		-- not buffer
		tmp_cols=tmp_cols||',flag_technical_storno integer NOT NULL DEFAULT 0,_pk_num_link_from_storno bigint references '||tmp_tb_name||'(_pk_num),id_load_log bigint';
	else
		-- buffer
		tmp_tb_name=tmp_tb_name||'_buffer';		
	end if;
	-- add create table string
	tmp_result='create table '||tmp_tb_name||'(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,'||tmp_cols||',hash_key character varying(32) NOT NULL GENERATED ALWAYS AS ('||tmp_cols1||') STORED)';
	return tmp_result;
end
$BODY$;


