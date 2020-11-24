-- PROCEDURE: public.sp_load_data_to_the_journal_buffer(character varying, bigint, boolean)

-- DROP PROCEDURE public.sp_load_data_to_the_journal_buffer(character varying, bigint, boolean);

CREATE OR REPLACE PROCEDURE public.sp_load_data_to_the_journal_buffer(
	journal_name character varying,
	id_condition0 bigint,
	flag_create_update_journal boolean DEFAULT false)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE id_log0 bigint;
DECLARE id_hash_log0 bigint;
DECLARE sql_text character varying DEFAULT '';
begin
	id_jur0=(select j.id_jur from public._config_journals j where j.journal_name=$1);
	-- check and correct journal
	CALL public.sp_check_and_correct_journal(journal_name,0,flag_create_update_journal);
	-- check and correct buffer of journal
	CALL public.sp_check_and_correct_journal(journal_name,1,flag_create_update_journal);
	-- check the condition_id
	CALL public.sp_check_the_condition(journal_name,id_condition0);
	-- need to add some other checks
	-- a) match between source and journal columns (full or not)
	CALL public.sp_check_columns_journal_srouces($1);
	-- b) that source table exists with particular columns
	
	-- check hash and correct buffer of journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,1,flag_create_update_journal);		
	-- check hash and correct journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,0,flag_create_update_journal);	
	-- if were no errors, continue
	
	-- insert log entry of loading
	insert into public._config_journals_log (id_jur,condition_id) select id_jur0,id_condition0;
	-- the last id_log of buffer
	id_log0=(select max(id_log) from public._config_journals_log where id_jur=id_jur0);
	-- last id_hash_log of journal
	id_hash_log0=(select max(id_hash_log) from public._config_journals_hash_log where id_jur=id_jur0);
	-- get sql query to insert buffer
	sql_text=(select public.func_get_sql_insert_buffer(id_jur0,id_log0,id_hash_log0));	
	-- insert into buffer
	EXECUTE sql_text;
	-- update flag in log, that buffer was loaded
	update	public._config_journals_log
	set		flag_was_loaded_to_journal_buffer=TRUE
	where	id_log=id_log0;
end
$BODY$;
