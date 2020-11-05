-- PROCEDURE: public.sp_check_the_condition(character varying, bigint)

-- DROP PROCEDURE public.sp_check_the_condition(character varying, bigint);

CREATE OR REPLACE PROCEDURE public.sp_check_the_condition(
	journal_name character varying,
	id_condition0 bigint)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE id_jur0 bigint;
DECLARE sql_text character varying DEFAULT '';
begin
	/*	CHECK INPUT DATA	*/
	-- check journal_name
	id_jur0=(select	c.id_jur from public._config_journals c where c.journal_name=$1);
	-- check condition_id
	if 	id_condition0 is not null and not exists (select 1 from public._config_conditions c where c.id_condition=id_condition0) then
		-- cant find id condition
		raise exception 'Cant find ID condition ''%''!',id_condition0;
	else
		-- ok
		if id_condition0 is NULL then
			raise notice 'OK: condition is empty, full update journal';
		else
			raise notice 'OK: condition ID ''%'' was found.',id_condition0;
			-- check that columns for this condition_id exists
			if exists (	select 	z.id_analytic
					   	from 	public.func_get_table_of_analytic_id_for_condition_id(id_condition0) z
					  	except
					   	select	distinct j.id_analytic
					   	from	public._config_journal_columns j
					  	where	j.id_jur=id_jur0	) then
				raise exception 'Cant find some analytics of condition ''%'' in journal ''%''!',id_condition0,journal_name;
			else
				raise notice 'OK: all analytic of condition exists in journal';			
			end if;
		end if;
	end if;
end
$BODY$;
