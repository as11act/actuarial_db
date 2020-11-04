-- FUNCTION: public.func_get_SQL_of_condition_id(bigint)

-- DROP FUNCTION public."func_get_SQL_of_condition_id"(bigint);

CREATE OR REPLACE FUNCTION public."func_get_SQL_of_condition_id"(
	id_condition bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare result_sql_text character varying;
declare sql_text0 character varying;
declare flag_bool boolean;
declare parents RECORD;
declare childs RECORD;
begin
	-- temp table for calculate dependences of conditions
	CREATE TEMP TABLE conditions (id_condition_src bigint, id_condition_dst bigint, flag_add_not_to_src integer,level_from_the_top integer,sql_text character varying);
	-- define - its group of conditions or atomic
	if (select c.type_condition_aggregate from public._config_conditions c where c.id_condition=$1) is not NULL then
		-- so its group of conditions
		-- calculate dependences for the TOP condition_id = $1
		with recursive conditions_net as
		(	select	n.id_condition_src,n.id_condition_dst,n.flag_add_not_to_src,cast(1 as integer) level_from_the_top
			from	public._config_condition_net n
			where	n.id_condition_dst=$1
			union all
			select	n1.id_condition_src,n1.id_condition_dst,n1.flag_add_not_to_src,n0.level_from_the_top+1
			from	public._config_condition_net n1
					inner join conditions_net n0 on n0.id_condition_src=n1.id_condition_dst		)
		-- all dependences for particular id_condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top
		from 	conditions_net
		union all
		-- add atomic conditions
		select	NULL,id_condition_src,0 flag_add_not_to_src,(select max(level_from_the_top) from conditions_net)+1 level_from_the_top
		from	conditions_net t
		where	not exists (	select	1
						   		from	public._config_condition_net t0
						   		where	t0.id_condition_dst=t.id_condition_src	);
	else
		-- so its not group condition
		insert into conditions (id_condition_src,id_condition_dst,flag_add_not_to_src,level_from_the_top)
		select	NULL,c.id_condition,0,1
		from	public._config_conditions c
		where	c.id_condition=$1;
	end if;
	
	-- update all atomic conditions
	update	conditions c
	set		sql_text=(case 
					  	-- condition ALL = always TRUE
					  	when	c0.type_condition_aggregate='ALL' then '(1=1)'
					  	-- atomic conditions
					  	when	c0.analytic_type_compare='EQUAL'	then 
								'('||a.analytic_column_name||'='||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||a.analytic_column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_EQUAL'	then 
								'('||a.analytic_column_name||'<>'||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' or '||a.analytic_column_name||' is NULL)'
						when	c0.analytic_type_compare='LIKE'	then 
								'('||a.analytic_column_name||' like '||''''||c0.analytic_value_text||''''||' and '||a.analytic_column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_LIKE'	then 
								'('||a.analytic_column_name||' not like '||''''||c0.analytic_value_text||''''||' or '||a.analytic_column_name||' is NULL)'
						when	c0.analytic_type_compare='IN'	then 
								'('||a.analytic_column_name||' in '||c0.analytic_value_text||' and '||a.analytic_column_name||' is not NULL)'
						when	c0.analytic_type_compare='NOT_IN'	then 
								'('||a.analytic_column_name||' not in '||c0.analytic_value_text||' or '||a.analytic_column_name||' is NULL)'
						when	c0.analytic_type_compare in ('>=','>','<=','<')	then 
								'('||a.analytic_column_name||c0.analytic_type_compare||(case when a.type_value='float' then cast(c0.analytic_value_float as character varying) else ''''||c0.analytic_value_text||'''' end)||' and '||a.analytic_column_name||' is not NULL)'
					  end)
	from	public._config_conditions c0,
			public._config_analytics a
	where	c0.id_condition=c.id_condition_dst and
			a.id_analytic=c0.id_analytic and
			c.sql_text is NULL and
			(	c0.type_condition_aggregate='ALL' or
				c0.type_condition_aggregate is NULL	);
	
	-- iterate group conditions from bottom to top
	flag_bool=TRUE;	
	-- exists null values of sql_text?
	if (select count(*) from conditions where sql_text is NULL)=0 then
		flag_bool=FALSE;
	end if;		
	-- while NULL values exists
	while	flag_bool loop
		-- aggregate conditions with null sql_text, but all depends already calculated
		for	parents in
			select	distinct c.id_condition_dst,c0.type_condition_aggregate
			from	conditions c
					inner join public._config_conditions c0 on c0.id_condition=c.id_condition_dst
			where	c.sql_text is NULL and 
					c0.type_condition_aggregate is not NULL and
					c0.type_condition_aggregate<>'ALL' and
					not exists (	select	1
									from	conditions c0
									where	c0.id_condition_dst=c.id_condition_src and
											c0.sql_text is NULL	)
		loop
			sql_text0='';
			for	childs in
				select	c0.sql_text,c.flag_add_not_to_src
				from	-- parent
						conditions c
						-- childs
						inner join conditions c0 on c0.id_condition_dst=c.id_condition_src
				where	c.id_condition_dst=parents.id_condition_dst
			loop
				sql_text0=	sql_text0||
							(case when sql_text0='' then '' else ' '||parents.type_condition_aggregate||' ' end)||
							(case when childs.flag_add_not_to_src=1 then 'NOT '||childs.sql_text else childs.sql_text end);
			end loop;
			-- update with sql_text
			update	conditions c
			set		sql_text='('||sql_text0||')'
			where	c.id_condition_dst=parents.id_condition_dst;
		end loop;
		
		-- check: are there conditions with sql_text null? if not, then terminate
		if (select count(*) from conditions where sql_text is NULL)=0 then
			flag_bool=FALSE;
		end if;
	end loop;
	-- get result
	result_sql_text=(select sql_text from conditions where level_from_the_top=1 limit 1);
	-- drop tempory table
	drop table conditions;
	-- return result
	return result_sql_text;
end
$BODY$;

ALTER FUNCTION public."func_get_SQL_of_condition_id"(bigint)
    OWNER TO postgres;
