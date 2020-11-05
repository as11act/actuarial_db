-- PROCEDURE: public.sp_load_data_to_the_journal_buffer(character varying, bigint, boolean)

-- DROP PROCEDURE public.sp_load_data_to_the_journal_buffer(character varying, bigint, boolean);

CREATE OR REPLACE PROCEDURE public.sp_load_data_to_the_journal_buffer(
	journal_name character varying,
	id_condition bigint,
	flag_create_update_journal boolean DEFAULT false)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE journal_stage_table_name0 varchar(500);
DECLARE sql_text character varying DEFAULT '';
begin
	-- check and correct journal
	CALL public.sp_check_and_correct_journal(journal_name,0,flag_create_update_journal);
	-- check and correct buffer of journal
	CALL public.sp_check_and_correct_journal(journal_name,1,flag_create_update_journal);
	-- check the condition_id
	CALL public.sp_check_the_condition(journal_name,id_condition);
	
end
$BODY$;
