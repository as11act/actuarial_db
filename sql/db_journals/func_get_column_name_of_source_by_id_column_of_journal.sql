-- FUNCTION: public.func_get_column_name_of_source_by_id_column_of_journal(bigint, bigint)

-- DROP FUNCTION public.func_get_column_name_of_source_by_id_column_of_journal(bigint, bigint);

CREATE OR REPLACE FUNCTION public.func_get_column_name_of_source_by_id_column_of_journal(
	id_col_jur0 bigint,
	id_src0 bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
begin
	return	(	select	sc.column_name
				from	public._config_journal_column_match_source_column jms
			 			inner join public._config_source_columns sc on sc.id_col_src=jms.id_col_src and sc.id_src=id_src0
				where	jms.id_col_jur=id_col_jur0	);		
end
$BODY$;

ALTER FUNCTION public.func_get_column_name_of_source_by_id_column_of_journal(bigint, bigint)
    OWNER TO postgres;
