-- FUNCTION: public.func_get_sql_list_columns_of_journal(bigint, boolean)

-- DROP FUNCTION public.func_get_sql_list_columns_of_journal(bigint, boolean);

CREATE OR REPLACE FUNCTION public.func_get_sql_list_columns_of_journal(
	id_jur bigint,
	flag_storno boolean DEFAULT false)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
--DECLARE journal_stage_table_name0 varchar(500);
DECLARE tmp_result character varying DEFAULT '';
DECLARE cols RECORD;
begin
	-- stage table of journal
	--journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.id_jur=$1);
	
	for cols in 
		select	(case when a2.id_account is not NULL and flag_storno=TRUE then '(-1)*' else '' end)||j.column_name column_name_new
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1
	loop
		-- list of columns for alter table 
		tmp_result=tmp_result||(case when tmp_result='' then '' else ', ' end)||cols.column_name_new;
	end loop;
	-- return result
	return tmp_result;
end
$BODY$;

ALTER FUNCTION public.func_get_sql_list_columns_of_journal(bigint, boolean)
    OWNER TO postgres;
