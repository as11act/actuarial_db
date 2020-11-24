
CREATE OR REPLACE FUNCTION public.func_get_sql_hash_key_for_source(
	id_hash_log0 bigint,
	id_src0 bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
--DECLARE tmp_cols character varying DEFAULT '';
DECLARE tmp_hash_sql character varying DEFAULT '';
--DECLARE tmp_tb_name character varying;
--DECLARE tmp_result character varying;
DECLARE sql_text character varying DEFAULT '';
DECLARE cols RECORD;
begin
	for cols in 
		-- source column
		select	sc.column_name
		from	public._config_journal_hash_log_columns jhc
				inner join public._config_journals_hash_log jhl on jhl.id_hash_log=jhc.id_hash_log
				-- take info about journal columns
				inner join public._config_journal_columns jc on jc.column_name=jhc.column_name and jc.id_jur=jhl.id_jur
				-- link to columns of source
				inner join public._config_journal_column_match_source_column jcm on jcm.id_col_jur=jc.id_col_jur
				-- source columns of particular id_src0
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src and sc.id_src=id_src0
		where	jhc.id_hash_log=id_hash_log0
		order by jhc.order_n
	loop
		-- list of columns for HASH md5
		tmp_hash_sql=tmp_hash_sql||(case when tmp_hash_sql='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- add md5
	tmp_hash_sql='md5('||tmp_hash_sql||')';
	return tmp_hash_sql;
end
$BODY$;

