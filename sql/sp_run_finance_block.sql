-- PROCEDURE: public.sp_run_finance_block(bigint)

-- DROP PROCEDURE public.sp_run_finance_block(bigint);

CREATE OR REPLACE PROCEDURE public.sp_run_finance_block(
	id_block0 bigint)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE sql_text character varying DEFAULT '';
DECLARE id_function0 bigint;
DECLARE function_name0 character varying DEFAULT '';
DECLARE block_name0 character varying DEFAULT '';
begin
	/*	CHECK INPUT DATA	*/
	id_function0=(select id_function from public._finance_blocks where id_block=id_block0);
	block_name0=(select block_name from public._finance_blocks where id_block=id_block0);
	function_name0=(select function_name from public._finance_functions where id_function=id_function0);
	if block_name0 is NULL
	then
		-- block doesn't exists
		raise exception 'Block id ''%'' doesn''t exists!',id_block0;
	else
		-- block exists
		if not exists (select	1 from information_schema.routines where routine_schema='public' and routine_type='PROCEDURE' and routine_name=function_name0)
		then
			raise exception 'Cant find function name ''%'' for function id ''%'', block name ''%'', block id ''%''!',function_name0,id_function0,block_name0,id_block0;
		else
			raise notice 'OK: We''ve found function name ''%'' for function id ''%'', block name ''%'', block id ''%''!',function_name0,id_function0,block_name0,id_block0;
			-- check that all parameters exists
			if	-- exists extra parametres in real function
				exists	(		select	pars.parameter_name
								from 	information_schema.parameters pars 
										inner join information_schema.routines proc 
										on	proc.specific_schema=pars.specific_schema and
											proc.specific_name=pars.specific_name
								where 	pars.specific_schema='public' and
										proc.routine_type='PROCEDURE' and 
										proc.routine_name=function_name0
								except
								select	f.parameter_name
						 		from	public._finance_function_parametres f
						 		where	id_function=id_function0	)
				or
				-- exists extra parameters in template function
				exists	(		select	f.parameter_name
						 		from	public._finance_function_parametres f
						 		where	id_function=id_function0
						 		except
								select	pars.parameter_name
								from 	information_schema.parameters pars 
										inner join information_schema.routines proc 
										on	proc.specific_schema=pars.specific_schema and
											proc.specific_name=pars.specific_name
								where 	pars.specific_schema='public' and
										proc.routine_type='PROCEDURE' and 
										proc.routine_name=function_name0	)				
			then
				-- exists parametres which are not the same
				raise exception 'There are not the same parametres in REAL function ''%'' and in TEMPLATE!',function_name0;
			else
				raise notice 'OK: There are the same parametres in REAL function ''%'' and in TEMPLATE!',function_name0;
			end if;
		end if;	
	end if;
end
$BODY$;
