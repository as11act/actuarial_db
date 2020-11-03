-- FUNCTION: public.func_get_sql_create_buffer()

-- DROP FUNCTION public.func_get_sql_create_buffer();

CREATE OR REPLACE FUNCTION public.func_get_sql_create_buffer(id_jur bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE tmp1 character varying;
DECLARE tmp2 character varying;
DECLARE cols RECORD;
--DECLARE cols character varying;
begin
	tmp1='';
	for cols in 
		select	-- name of buffer column
				coalesce(a1.analytic_name,a2.account_name)||' '||
			(	case 	
				 	when j.id_account is NOT NULL or a1.type_value='float'
			   			then	'float' 
			   		when a1.type_value='string'
			   			then	'character varying' 
			   		when a1.type_value='date'
			   			then	'date' 			   
			   		else 'character varying'
			  	end	) column_name
		from	public._config_journal_columns j
				left join public._config_analytics a1 on a1.id_analytic=j.id_analytic
				left join public._config_accounts a2 on a2.id_account=j.id_account
		where	j.id_jur=$1
	loop
		tmp1=tmp1||(case when tmp1='' then '' else ',
					' end)||cols.column_name;
	end loop;
	-- journal_name
	tmp2=(select journal_stage_table_name from public._config_journals j where j.id_jur=$1);
	tmp2=tmp2||'_buffer';
	-- add create table string
	tmp1='create table '||tmp2||'(_pk_num bigint NOT NULL GENERATED ALWAYS AS IDENTITY primary key,'||tmp1||')';
	return tmp1;
end
$BODY$;

