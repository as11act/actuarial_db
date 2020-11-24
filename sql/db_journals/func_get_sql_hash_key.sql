-- FUNCTION: public.func_get_sql_hash_key(bigint)

-- DROP FUNCTION public.func_get_sql_hash_key(bigint);

CREATE OR REPLACE FUNCTION public.func_get_sql_hash_key(
	id_hash_log0 bigint)
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
		select	j.column_name
		from	public._config_journal_hash_log_columns j
		where	j.id_hash_log=id_hash_log0
		order by j.order_n
	loop
		-- list of columns for HASH md5
		tmp_hash_sql=tmp_hash_sql||(case when tmp_hash_sql='' then '' else '||' end)||'coalesce(cast('||cols.column_name||' as character varying),''cNULL'')';
	end loop;
	-- add md5
	tmp_hash_sql='md5('||tmp_hash_sql||')';
	return tmp_hash_sql;
end
$BODY$;

ALTER FUNCTION public.func_get_sql_hash_key(bigint)
    OWNER TO postgres;
