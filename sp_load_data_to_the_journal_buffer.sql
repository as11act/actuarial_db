-- PROCEDURE: public.sp_load_data_to_the_journal_buffer()

-- DROP PROCEDURE public.sp_load_data_to_the_journal_buffer();

CREATE OR REPLACE PROCEDURE public.sp_load_data_to_the_journal_buffer(
	journal_name varchar(500),
	id_condition bigint
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur bigint;
begin
	-- check journal_name
	id_jur=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	if	id_jur is NULL then
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
end
$BODY$;

COMMENT ON PROCEDURE public.sp_load_data_to_the_journal_buffer()
    IS 'This procedure runs scripts to fill journal buffer table from sources. Part of sources to load configured by condition_id.';
