-- PROCEDURE: public.sp_load_data_to_the_journal_buffer()

-- DROP PROCEDURE public.sp_load_data_to_the_journal_buffer();

CREATE OR REPLACE PROCEDURE public.sp_load_data_to_the_journal_buffer(
	journal_name varchar(500),
	id_condition bigint,
	flag_create_update_journal boolean DEFAULT FALSE
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE journal_stage_table_name0 varchar(500);
DECLARE sql_text character varying DEFAULT '';
begin
	/*	CHECK INPUT DATA	*/
	-- check journal_name
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.journal_name=$1);

	if	id_jur0 is NULL then
		-- journal doesnt exists
		if journal_name is NULL then
			raise exception 'Journal_name cant be NULL!';
		else
			raise exception 'Cant find journal ''%'' in config tables!',journal_name;
		end if;
	else
		raise notice 'OK: journal ''%'' was found in config tables.',journal_name;
	end if;
	-- check condition_id
	if 	id_condition is not null and not exists (select 1 from public._config_conditions c where c.id_condition=$2) then
		-- cant find id condition
		raise exception 'Cant find ID condition ''%''!',id_condition;
	else
		-- ok
		if id_condition is NULL then
			raise notice 'OK: condition is empty, full update journal';
		else
			raise notice 'OK: condition ID ''%'' was found.',id_condition;
			-- check that columns for this condition_id exists
			if exists (	select 	z.id_analytic
					   	from 	public.func_get_table_of_analytic_id_for_condition_id($2) z
					  	except
					   	select	distinct j.id_analytic
					   	from	public._config_journal_columns j	  ) then
				raise exception 'Cant find some analytics of condition ''%'' in journal ''%''!',id_condition,journal_name;
			else
				raise notice 'OK: all analytic of condition exists in journal';			
			end if;
		end if;
	end if;

	/*	CHECK JOURNALS - Exsists or not	*/
	if 	-- not buffer
		not exists (	select	1
				  	from	information_schema.tables t
				   			inner join public._config_journals c on c.journal_stage_table_name=t.table_name and t.table_schema='public'
				  	where	c.id_jur=id_jur0	)
		or
		-- buffer
		not exists (	select	1
				  	from	information_schema.tables t
				   			inner join public._config_journals c on (c.journal_stage_table_name||'_buffer')=t.table_name and t.table_schema='public'
				  	where	c.id_jur=id_jur0	)
	then
		if not exists (	select	1
						from	information_schema.tables t
								inner join public._config_journals c on c.journal_stage_table_name=t.table_name and t.table_schema='public'
						where	c.id_jur=id_jur0	) then
		-- dont exists not buffer table
			raise notice 'INFO: journal ''%'', table ''%'' doesnt exists.',journal_name,journal_stage_table_name0;			
			-- journal doesnt exists
			if flag_create_update_journal then
				-- flag = TRUE
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets create table.';			
				sql_text=(select public.func_get_sql_create_journal(id_jur0, 0));
				EXECUTE sql_text;
				--raise notice 'INFO: SQL_TEXT: %',sql_text;
			else
				-- flag = FALSE
				raise exception 'The flag_create_update_journal=FALSE, so we didnt created any journals. Please turn flag to TRUE or create table journal by your own.';			
			end if;
		end if;
		
		if not exists (	select	1
						from	information_schema.tables t
								inner join public._config_journals c on (c.journal_stage_table_name||'_buffer')=t.table_name and t.table_schema='public'
						where	c.id_jur=id_jur0	) then
		-- dont exists buffer table
			raise notice 'INFO: journal buffer ''%'', table ''%'' doesnt exists.',journal_name,(journal_stage_table_name0||'_buffer');			
			-- journal doesnt exists
			if flag_create_update_journal then
				-- flag = TRUE
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets create buffer table.';			
				sql_text=(select public.func_get_sql_create_journal(id_jur0, 1));
				EXECUTE sql_text;
				--raise notice 'INFO: SQL_TEXT: %',sql_text;
			else
				-- flag = FALSE
				raise exception 'The flag_create_update_journal=FALSE, so we didnt created any journals. Please turn flag to TRUE or create table journal by your own.';			
			end if;
		end if;
	--else
		-- journal exists
	end if;
end
$BODY$;

COMMENT ON PROCEDURE public.sp_load_data_to_the_journal_buffer()
    IS 'This procedure runs scripts to fill journal buffer table from sources. Part of sources to load configured by condition_id.';
