CREATE OR REPLACE PROCEDURE public.sp_load_data_from_buffer_to_journal(
	journal_name character varying,
	flag_create_update_journal boolean DEFAULT false	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE id_log0 bigint;
DECLARE id_hash_log0 bigint;
DECLARE journal_stage_table_name0 character varying DEFAULT '';
DECLARE sql_text character varying DEFAULT '';
begin
	-- get id_jur of journal by name
	id_jur0=(select j.id_jur from public._config_journals j where j.journal_name=$1);
	-- get stage name of journal
	journal_stage_table_name0=(select j.journal_stage_table_name from public._config_journals j where j.journal_name=$1);
	-- so beffer table is
	journal_stage_table_name0=journal_stage_table_name0||'_buffer';
	-- check and correct journal
	CALL public.sp_check_and_correct_journal(journal_name,0,flag_create_update_journal);
	-- check hash and correct journal
	CALL public.sp_check_create_the_hash_of_journal(journal_name,0,flag_create_update_journal);	
	-- if were no errors, continue
	
	-- the last id_log of buffer table
	sql_text='select distinct id_log from '||journal_stage_table_name0;
	EXECUTE sql_text INTO id_log0;
	-- last id_hash_log of journal
	sql_text='select distinct id_hash_log from '||journal_stage_table_name0;
	EXECUTE sql_text INTO id_hash_log0;	
	-- get sql query to insert buffer
	sql_text=(select public.func_get_sql_insert_journal(id_jur0,id_log0,id_hash_log0));	
	-- insert into buffer
	EXECUTE sql_text;
	-- update flag when journal was updated
	update	public._config_journals_log
	set		flag_was_loaded_to_journal=TRUE
	where	id_log=id_log0;
end
$BODY$;
