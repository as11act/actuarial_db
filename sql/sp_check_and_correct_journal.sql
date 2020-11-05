-- PROCEDURE: public.sp_check_and_correct_journal(character varying, integer, boolean)

-- DROP PROCEDURE public.sp_check_and_correct_journal(character varying, integer, boolean);

CREATE OR REPLACE PROCEDURE public.sp_check_and_correct_journal(
	journal_name character varying,
	flag_buffer integer,
	flag_create_update_journal boolean DEFAULT false)
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
	-- buffer or journal
	if flag_buffer=1 then
		-- so its buffer, correct name of stage table
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;

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
	
	/*	CHECK JOURNALS - Exsists or not	*/
	if 	not exists (	select	1
				  		from	information_schema.tables t
				  		where	t.table_name=journal_stage_table_name0 and
								t.table_schema='public'	)
	then
		-- dont exists table
		raise notice 'INFO: journal ''%'', table ''%'' doesnt exists.',journal_name,journal_stage_table_name0;			
		-- journal doesnt exists
		if flag_create_update_journal then
			-- flag = TRUE
			raise notice 'INFO: the flag_create_update_journal TRUE, so lets create table.';			
			sql_text=(select public.func_get_sql_create_journal(id_jur0, flag_buffer));
			EXECUTE sql_text;
		else
			-- flag = FALSE
			raise exception 'The flag_create_update_journal=FALSE, so we didnt created any journals. Please turn flag to TRUE or create table journal by your own.';			
		end if;
	else
		-- journal exists, lets check that all columns exists also
		if 	-- exists technical columns which are not in table 
			exists (	-- technical columns of journal
						select	v.column_name
						from	public.view_technical_column_of_journals v
						where	flag_buffer=0
						union all
						-- technical columns of buffer of journal
						select	v.column_name
						from	public.view_technical_column_of_journals_buffer v
						where	flag_buffer=1
						except
						select	c.column_name
						from	information_schema.columns c
						where 	c.table_name=journal_stage_table_name0 and c.table_schema='public'	)
			or
			-- exists columns of journal which not in table
			exists	(	select	j.column_name
						from	public._config_journal_columns j
						where	j.id_jur=id_jur0
						except
						select	c.column_name
						from	information_schema.columns c
						where	c.table_name=journal_stage_table_name0 and c.table_schema='public'	) 
		then
		-- exists some columns which are not in table
			raise notice 'INFO: journal ''%'', doesnt have some journal columns in table ''%''.',journal_name,journal_stage_table_name0;
			if flag_create_update_journal then
				-- flag = TRUE, then we should add columns
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets add additional columns.';			
				sql_text=(select public.func_get_sql_new_columns(id_jur0, flag_buffer));
				EXECUTE sql_text;
			else
				-- flag = FALSE, we cant add columns
				raise exception 'The flag_create_update_journal=FALSE, so we didnt created any new columns. Please turn flag to TRUE for append columns automaticaly.';			
			end if;		
		else
		-- OK
			raise notice 'INFO: all columns exists, no errors.';			
		end if;
	end if;
end
$BODY$;
