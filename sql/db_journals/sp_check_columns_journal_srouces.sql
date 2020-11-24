-- PROCEDURE: public.sp_check_create_the_hash_of_journal(character varying, integer, boolean)

-- DROP PROCEDURE public.sp_check_create_the_hash_of_journal(character varying, integer, boolean);

CREATE OR REPLACE PROCEDURE public.sp_check_columns_journal_srouces(
	journal_name character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE cols RECORD;
begin
	-- id of journal
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	-- loop for all sources
	for cols in 
		select	distinct 
				s.id_src,
				s.db_name,
				s.schema_name,
				s.table_name
		from	-- link columns journal-source
				public._config_journal_column_match_source_column jcm
				-- our journal columns
				inner join public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur and jc.id_jur=id_jur0
				-- sources column for journal
				inner join public._config_source_columns sc on sc.id_col_src=jcm.id_col_src
				-- sources 
				inner join public._config_sources s on s.id_src=sc.id_src
		order by s.id_src
	loop
		-- generate sql to insert sources
		-- check the source id_src: do exists columns of journal without link to source?
		if exists (	select	jc.column_name
				  	from	public._config_journal_columns jc
				   	where	jc.id_jur=id_jur0
				   	except
					select	jc.column_name
					from	public._config_journal_column_match_source_column jcm
							inner join 	public._config_source_columns sc on sc.id_col_src=jcm.id_col_src 
							inner join  public._config_journal_columns jc on jc.id_col_jur=jcm.id_col_jur 
					where	sc.id_src=cols.id_src and
							jc.id_jur=id_jur0	) then
			-- so, there exist columns, which are not full linked to source
			raise exception	'The source id_src=%, table source = %.%.% not full linked to journal ''%'' (some columns of journal didn''t link)',
					cols.id_src,
					cols.db_name,
					cols.schema_name,
					cols.table_name,
					$1;
		else
			raise notice 'OK: the source id_src=%, table source = %.%.% full linked to journal ''%''',
					cols.id_src,
					cols.db_name,
					cols.schema_name,
					cols.table_name,
					$1;
		end if;
	end loop;
end
$BODY$;
