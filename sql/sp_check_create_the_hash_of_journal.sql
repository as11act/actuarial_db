-- PROCEDURE: public.sp_check_create_the_hash_of_journal(character varying, integer, boolean)

-- DROP PROCEDURE public.sp_check_create_the_hash_of_journal(character varying, integer, boolean);

CREATE OR REPLACE PROCEDURE public.sp_check_create_the_hash_of_journal(
	journal_name character varying,
	flag_buffer integer,
	flag_create_update_journal boolean DEFAULT false)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE id_hash_log0 bigint;
DECLARE id_hash_log1 bigint;
DECLARE journal_stage_table_name0 varchar(500);
DECLARE sql_text character varying DEFAULT '';
DECLARE sql_hash_key character varying DEFAULT '';
DECLARE flag_create_hash boolean DEFAULT FALSE;
DECLARE flag_recalculate_hash boolean DEFAULT FALSE;
DECLARE flag_update_hash boolean DEFAULT FALSE;
begin
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	journal_stage_table_name0=(select	c.journal_stage_table_name from public._config_journals c where c.journal_name=$1);
	if flag_buffer=1 then
		-- its buffer, add prefix
		journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	end if;
	-- get the last hash information
	id_hash_log0=(	select	c.id_hash_log
					from	public._config_journals_hash_log c
					where	c.id_jur=id_jur0  and
							insert_timestamp=(	select 	max(c0.insert_timestamp) 
												from 	public._config_journals_hash_log c0
												where	c0.id_jur=c.id_jur	)	);
	if id_hash_log0 is NULL then
		-- so hash doesnt exists
		raise notice 'INFO: hash didnt exists for journal ''%''',journal_name;
		if flag_create_update_journal then
			-- ok, lets create hash
			raise notice 'INFO: the flag_create_update_journal TRUE, so lets create hash.';	
			flag_create_hash=TRUE;
		else
			-- we cant create hash
			raise exception 'The flag_create_update_journal=FALSE, so we didnt created any hash. Please turn flag to TRUE or create hash journal.';			
		end if;
	else
		-- hash exists, lets check columns
		if	-- more columns in journal
			exists (	select	jc.column_name
				   		from	public._config_journal_columns jc
				   		where	jc.id_jur=id_jur0
				   		except
				   		select	jhc.column_name
						from	public._config_journal_hash_log_columns	jhc
				   		where	jhc.id_hash_log=id_hash_log0	) 
			or
			-- more columns in hash
			exists (	select	jhc.column_name
						from	public._config_journal_hash_log_columns	jhc
				   		where	jhc.id_hash_log=id_hash_log0
						except
						select	jc.column_name
				   		from	public._config_journal_columns jc
				   		where	jc.id_jur=id_jur0	) 		then
			-- so exists some extra columns, need to recalculate hash
			raise notice 'INFO: exists some extra columns in journal/hash which are not in hash/journal.';	
			if flag_create_update_journal then
				-- ok, lets recalculate hash
				raise notice 'INFO: the flag_create_update_journal TRUE, so lets recalculate hash.';	
				flag_recalculate_hash=TRUE;
			else
				-- we cant recalculate hash
				raise exception 'The flag_create_update_journal=FALSE, so we didnt recalculate hash. Please turn flag to TRUE or recalculate hash journal.';			
			end if;
		else
			-- ok with hash columns
			-- lets take distinct id_hash_log
			sql_text='select distinct id_hash_log from '||journal_stage_table_name0;
			EXECUTE sql_text INTO id_hash_log1;
			-- lets check that journal hash this id_hash_log of hash
			if 	id_hash_log1 is NULL 
				or
				id_hash_log1<>id_hash_log0 then
				-- so, there are null hash_id or different id_hash_log - strange ... 
				if id_hash_log1 is NULL then
					-- hash is NULL
					raise notice 'INFO: the id_hash_log of journal ''%'' in table ''%'' is NULL.',journal_name,journal_stage_table_name0;	
				else
					-- different
					raise notice 'INFO: the id_hash_log of journal ''%'' in table ''%'' and in hash config are different.',journal_name,journal_stage_table_name0;	
				end if;				
				if flag_create_update_journal or id_hash_log1 is NULL then
					-- ok, lets recalculate hash
					if id_hash_log1 is NULL then
						-- also update hash
						raise notice 'INFO: hash is NULL, lets update.';	
					else
						-- recalculate hash
						raise notice 'INFO: the flag_create_update_journal TRUE, so lets recalculate hash.';	
					end if;										
					flag_update_hash=TRUE;
				else
					-- we cant recalculate hash
					raise exception 'The flag_create_update_journal=FALSE, so we didnt recalculate hash. Please turn flag to TRUE or recalculate hash journal.';			
				end if;

			else
				-- id_hash_log - the same, OK
				raise notice 'OK: the hash is normal';	
			end if;			
		end if;
	end if;
	
	if 	flag_create_hash or 
		flag_recalculate_hash or
		flag_update_hash	then
		-- create hash and recalculate hash here
		-- we need to construct the new seq of columns in hash, store in config, update hash_key for current date in table
		if NOT flag_update_hash then
			-- create new hash id if not only update need
			insert into public._config_journals_hash_log (id_jur,flag_journal_was_updated_by_hash)	select	id_jur0,FALSE;
			-- the last id_hash
			id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
			-- insert columns for this hash
			insert into public._config_journal_hash_log_columns (id_hash_log,column_name,order_n)
			select	id_hash_log0,column_name,row_number() over(order by column_name asc) order_n
			from	public._config_journal_columns jc
			where	jc.id_jur=id_jur0;			
		else
			-- need only update, so get current hash id
			-- the last id_hash
			id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
		end if;
		-- set hash key string
		sql_hash_key=func_get_sql_hash_key(id_hash_log0);
		-- update hash_key in table
		sql_text='update '||journal_stage_table_name0||' set hash_key='||sql_hash_key;
		-- execute update
		EXECUTE sql_text;
		-- update config hash table that update is done
		if flag_buffer=0 then
			update	_config_journals_hash_log
			set		flag_journal_was_updated_by_hash=TRUE
			where	id_hash_log=id_hash_log0;
		else
			update	_config_journals_hash_log
			set		flag_journal_was_updated_by_hash_buffer=TRUE
			where	id_hash_log=id_hash_log0;		
		end if;
	end if;
end
$BODY$;
